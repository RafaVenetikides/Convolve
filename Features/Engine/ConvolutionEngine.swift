//
//  ConvolutionScanEngine.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 19/02/26.
//

import SwiftUI

@MainActor
final class ConvolutionEngine: ObservableObject {

    @Published var originalUIImage: UIImage?
    @Published var outputs: [Image?] = []

    @Published var cursorX: Int = 0
    @Published var cursorY: Int = 0
    @Published var isRunning: Bool = false
    @Published private(set) var isFinished = false

    @Published private(set) var imageWidth: Int = 1
    @Published private(set) var imageHeight: Int = 1
    @Published private(set) var mode: PixelMode = .grayscale

    var pixelsPerTick: Double = 2
    var renderFPS: Double = 15

    private var kernels: [KernelSpec] = []
    private var normalizer: (@Sendable (KernelSpec, [Float]) -> [Float])? = nil

    private var input: [Float] = []

    private var fullOutputs: [[Float]] = []
    private var revealedOutputs: [[Float]] = []

    private var timer: Timer?
    private var computeTask: Task<Void, Never>?
    private var isComputing = false
    private var lastRenderTime: CFTimeInterval = 0

    func configure(
        assetName: String,
        mode: PixelMode,
        kernels: [KernelSpec],
        normalizer: (@Sendable (KernelSpec, [Float]) -> [Float])? = nil
    ) {
        guard !kernels.isEmpty else {
            outputs = []
            revealedOutputs = []
            fullOutputs = []
            return
        }
        stop()

        self.mode = mode
        self.kernels = kernels
        self.normalizer = normalizer

        switch mode {
        case .argbffff:
            guard
                let loaded = ImageUtils.loadARGBFFFFBuffer(assetName: assetName)
            else { return }
            originalUIImage = loaded.original
            imageWidth = loaded.width
            imageHeight = loaded.height
            input = loaded.buffer

        case .grayscale:
            guard
                let loaded = ImageUtils.loadGrayscaleBuffer(
                    assetName: assetName
                )
            else { return }
            originalUIImage = loaded.original
            imageWidth = loaded.width
            imageHeight = loaded.height
            input = loaded.buffer
        }

        cursorX = 0
        cursorY = 0
        isComputing = false
        lastRenderTime = 0

        let pixelCount = max(0, imageWidth * imageHeight)
        let stride = mode.stride
        let bufferCount = pixelCount * stride

        fullOutputs = []
        revealedOutputs = Array(
            repeating: Array(repeating: 0, count: bufferCount),
            count: kernels.count
        )

        outputs = Array(
            repeating: Self.makeImage(
                from: Array(repeating: 0, count: bufferCount),
                width: imageWidth,
                height: imageHeight,
                mode: mode
            ),
            count: kernels.count
        )

        isFinished = false
    }

    func start() {
        guard !isRunning else { return }
        guard imageWidth > 0, imageHeight > 0, !input.isEmpty, !kernels.isEmpty
        else { return }

        isRunning = true
        isFinished = false
        startComputeIfNeeded()
        startTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil

        computeTask?.cancel()
        computeTask = nil

        isRunning = false
    }

    func reset() {
        stop()

        cursorX = 0
        cursorY = 0

        let pixelCount = max(0, imageWidth * imageHeight)
        let bufferCount = pixelCount * mode.stride

        fullOutputs = []
        revealedOutputs = Array(
            repeating: Array(repeating: 0, count: bufferCount),
            count: kernels.count
        )

        outputs = Array(
            repeating: Self.makeImage(
                from: Array(repeating: 0, count: bufferCount),
                width: imageWidth,
                height: imageHeight,
                mode: mode
            ),
            count: kernels.count
        )

        isComputing = false
        isFinished = false
        lastRenderTime = 0
    }

    func stepOnce() {
        tick()
    }

    private func startTimer() {
        timer?.invalidate()
        lastRenderTime = 0

        let t = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 60.0,
            repeats: true
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        guard imageWidth > 0, imageHeight > 0 else { return }

        advanceCursor()
        revealIfPossible()
        scheduleRenderIfNeeded()

        if cursorY >= imageHeight {
            // finished scan
            if fullOutputs.isEmpty && isComputing { return }

            if !fullOutputs.isEmpty {
                revealAll()
                scheduleRenderIfNeeded()
            }

            timer?.invalidate()
            timer = nil
            isRunning = false
            isFinished = true
        }
    }

    private func advanceCursor() {
        let steps = max(1, Int(pixelsPerTick))

        var idx = cursorY * imageWidth + cursorX
        let maxIdx = imageWidth * imageHeight

        idx = min(idx + steps, maxIdx)

        if idx >= maxIdx {
            cursorX = 0
            cursorY = imageHeight
            return
        }

        cursorY = idx / imageWidth
        cursorX = idx % imageWidth
    }

    private func revealIfPossible() {
        guard !fullOutputs.isEmpty else { return }
        let pixelIndex = cursorY * imageWidth + cursorX
        revealOutput(upToPixelExclusive: pixelIndex)
    }

    private func revealAll() {
        revealOutput(upToPixelExclusive: imageWidth * imageHeight)
    }

    private func revealOutput(upToPixelExclusive pixelIndex: Int) {
        let pixelCount = imageWidth * imageHeight
        guard pixelCount > 0 else { return }

        let clampedPixel = min(max(pixelIndex, 0), pixelCount - 1)
        let pixelsToCopy = clampedPixel + 1

        let stride = mode.stride
        let count = pixelsToCopy * stride
        guard count > 0 else { return }

        for i in 0..<kernels.count {
            revealedOutputs[i].replaceSubrange(
                0..<count,
                with: fullOutputs[i][0..<count]
            )
        }
    }

    private func startComputeIfNeeded() {
        guard !isComputing, fullOutputs.isEmpty, !input.isEmpty else { return }
        isComputing = true

        computeTask?.cancel()

        let inputSnapshot = input
        let w = imageWidth
        let h = imageHeight
        let modeSnapshot = mode
        let kernelsSnapshot = kernels
        let normalizerSnapshot = normalizer

        computeTask = Task.detached(priority: .userInitiated) { [inputSnapshot, w, h, modeSnapshot, kernelsSnapshot, normalizerSnapshot] in
            let outs = Self.computeAll(
                input: inputSnapshot,
                width: w,
                height: h,
                mode: modeSnapshot,
                kernels: kernelsSnapshot,
                normalizer: normalizerSnapshot
            )

            if Task.isCancelled { return }

            await MainActor.run {
                self.fullOutputs = outs
                self.isComputing = false
                self.revealIfPossible()
            }
        }
    }


    nonisolated private static func computeAll(
        input: [Float],
        width: Int,
        height: Int,
        mode: PixelMode,
        kernels: [KernelSpec],
        normalizer: (@Sendable (KernelSpec, [Float]) -> [Float])?
    ) -> [[Float]] {
        var outs: [[Float]] = []
        outs.reserveCapacity(kernels.count)

        for k in kernels {
            if Task.isCancelled { break }
            let out: [Float]
            switch mode {
            case .argbffff:
                out = AccelerateConvolution.convolveARGBFFFF(
                    input: input,
                    width: width,
                    height: height,
                    kernel: k.weights,
                    kernelSize: k.size
                )
            case .grayscale:
                out = AccelerateConvolution.convolvePlanarFGrayscale(
                    input: input,
                    width: width,
                    height: height,
                    kernel: k.weights,
                    kernelSize: k.size
                )
            }

            if let norm = normalizer {
                outs.append(norm(k, out))
            } else {
                outs.append(out)
            }
        }

        return outs
    }


    private func scheduleRenderIfNeeded() {
        let now = CACurrentMediaTime()
        guard now - lastRenderTime >= (1.0 / renderFPS) else { return }
        lastRenderTime = now

        let w = imageWidth
        let h = imageHeight
        let modeSnapshot = mode
        let snapshot = revealedOutputs

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            var imgs: [Image?] = []
            imgs.reserveCapacity(snapshot.count)

            for buf in snapshot {
                imgs.append(
                    Self.makeImage(
                        from: buf,
                        width: w,
                        height: h,
                        mode: modeSnapshot
                    )
                )
            }

            await MainActor.run {
                self.outputs = imgs
            }
        }
    }

    nonisolated private static func makeImage(
        from buffer: [Float],
        width: Int,
        height: Int,
        mode: PixelMode
    ) -> Image? {
        let cg: CGImage?
        switch mode {
        case .argbffff:
            cg = ImageUtils.makeARGBFFFFCGImage(
                buffer: buffer,
                width: width,
                height: height
            )
        case .grayscale:
            cg = ImageUtils.makeGrascaleCGImage(
                buffer: buffer,
                width: width,
                height: height
            )
        }
        guard let cg else { return nil }
        return Image(decorative: cg, scale: 1.0)
    }
}
