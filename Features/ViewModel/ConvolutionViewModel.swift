//
//  ConvolutionViewModel.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 04/02/26.
//

import SwiftUI

@MainActor
final class ConvolutionViewModel: ObservableObject {

    @Published var originalUIImage: UIImage?
    @Published var outputImage: Image?

    @Published var useColor: Bool = true
    @Published var selectedPreset: KernelPreset = .boxBlur

    @Published var cursorX: Int = 0
    @Published var cursorY: Int = 0
    @Published var isRunning: Bool = false

    @Published var pixelsPerTick: Double = 100

    @Published private(set) var imageWidth: Int = 1
    @Published private(set) var imageHeight: Int = 1

    @Published var blurIntensity: BlurIntensity = .medium

    var currentKernelSize: Int {
        selectedPreset.kernelSize(width: imageWidth, height: imageHeight, intensity: blurIntensity)
    }

    var currentKernel: [Float] {
        selectedPreset.makeKernel(size: currentKernelSize)
    }

    private let renderFPS: Double = 15

    private var input: [Float] = []
    private var fullOutput: [Float] = []
    private var revealedOutput: [Float] = []

    private var timer: Timer?
    private var computeTask: Task<Void, Never>?
    private var isComputing = false

    private var lastRenderTime: CFTimeInterval = 0

    func setup(assetName: String) {
        if useColor {
            guard let loaded = ImageUtils.loadARGBFFFFBuffer(assetName: assetName) else { return }
            originalUIImage = loaded.original
            imageWidth = loaded.width
            imageHeight = loaded.height

            input = loaded.buffer
            revealedOutput = Array(repeating: 0, count: imageWidth * imageHeight * 4)
        } else {
            guard let loaded = ImageUtils.loadGrayscaleBuffer(assetName: assetName)     else { return }

            originalUIImage = loaded.original
            imageWidth = loaded.width
            imageHeight = loaded.height

            input = loaded.buffer
            revealedOutput = Array(repeating: 0, count: imageWidth * imageHeight)
        }

        fullOutput.removeAll(keepingCapacity: true)

        cursorX = 0
        cursorY = 0
        isComputing = false
        lastRenderTime = 0

        outputImage = makeOutputImage(from: revealedOutput)
    }

    func setPreset(_ preset: KernelPreset) {
        guard preset != selectedPreset else { return }
        selectedPreset = preset

        stop()
        cursorX = 0
        cursorY = 0
        fullOutput.removeAll(keepingCapacity: true)

        let stride = useColor ? 4 : 1
        revealedOutput = Array(repeating: 0, count: imageWidth * imageHeight * stride)
        isComputing = false

        outputImage = makeOutputImage(from: revealedOutput)

        startComputeIfNeeded()
    }

    func setBlurIntensity(_ intensity: BlurIntensity) {
        guard intensity != blurIntensity else { return }
        blurIntensity = intensity

        guard selectedPreset.isBlur else { return }

        stop()
        cursorX = 0
        cursorY = 0
        fullOutput.removeAll(keepingCapacity: true)

        let stride = useColor ? 4 : 1
        revealedOutput = Array(repeating: 0, count: imageWidth * imageHeight * stride)
        isComputing = false

        outputImage = makeOutputImage(from: revealedOutput)
        startComputeIfNeeded()
    }

    func togglePlay() {
        isRunning ? stop() : start()
    }

    func stepOnce() {
        tick()
    }

    func reset() {
        stop()

        cursorX = 0
        cursorY = 0

        fullOutput.removeAll(keepingCapacity: true)

        let stride = useColor ? 4 : 1
        revealedOutput = Array(repeating: 0, count: imageWidth * imageHeight * stride)
        isComputing = false

        outputImage = makeOutputImage(from: revealedOutput)
    }

    private func start() {
        isRunning = true
        startComputeIfNeeded()
        startTimer()
    }

    private func stop() {
        stopTimer()
        computeTask?.cancel()
        computeTask = nil
        isRunning = false
    }

    private func startTimer() {
        stopTimer()
        lastRenderTime = 0

        let t = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 60.0,
            repeats: true
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.tick()
            }
        }

        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard imageWidth > 0, imageHeight > 0 else { return }

        advanceCursor()
        revealIfPossible()
        scheduleRenderIfNeeded()

        if cursorY >= imageHeight {
            if fullOutput.isEmpty && isComputing {
                return
            }

            if !fullOutput.isEmpty {
                revealOutput(upToIndexExclusive: imageWidth * imageHeight)
                scheduleRenderIfNeeded()
            }

            stopTimer()
            isRunning = false
        }
    }

    private func advanceCursor() {
        let steps = max(1, Int(pixelsPerTick))

        var idx = cursorY * imageWidth + cursorX
        let maxIdx = imageWidth * imageHeight

        idx = min(idx + steps, maxIdx)
        if  idx >= maxIdx {
            cursorX = 0
            cursorY = imageHeight
            return
        }

        cursorY = idx / imageWidth
        cursorX = idx % imageWidth
    }

    private func revealIfPossible() {
        guard !fullOutput.isEmpty else { return }
        revealOutput(upToIndexExclusive: cursorY * imageWidth + cursorX)

    }

    private func revealOutput(upToIndexExclusive pixelIndex: Int) {
        let pixelCount = imageWidth * imageHeight
        let clampedPixel = min(max(pixelIndex, 0), pixelCount - 1)
        let pixelsToCopy = clampedPixel + 1

        let stride = useColor ? 4 : 1
        let count = pixelsToCopy * stride
        guard count > 0 else { return }

        revealedOutput.replaceSubrange(0..<count, with: fullOutput[0..<count])
    }

    private func startComputeIfNeeded() {
        guard !isComputing, fullOutput.isEmpty, !input.isEmpty else { return }

        isComputing = true

        let useColorSnapshot = useColor
        let inputSnapshot = input
        let w = imageWidth
        let h = imageHeight
        let k = currentKernel
        let ks = currentKernelSize

        computeTask?.cancel()
        computeTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let out: [Float]

            if useColorSnapshot {
                out = AccelerateConvolution.convolveARGBFFFF(
                    input: inputSnapshot,
                    width: w,
                    height: h,
                    kernel: k,
                    kernelSize: ks
                )
            } else {
                out = AccelerateConvolution.convolvePlanarFGrayscale(
                    input: inputSnapshot,
                    width: w,
                    height: h,
                    kernel: k,
                    kernelSize: ks
                )
            }

            await MainActor.run {
                self.fullOutput = out
                self.isComputing = false
                self.revealOutput(upToIndexExclusive: self.cursorY * self.imageWidth + self.cursorX)
            }
        }
    }

    private func scheduleRenderIfNeeded() {
        let now = CACurrentMediaTime()
        guard now - lastRenderTime >= (1.0 / renderFPS) else { return }
        lastRenderTime = now

        let snapshot = revealedOutput
        let w = imageWidth
        let h = imageHeight
        let useColorSnapshot = useColor

        renderImageAsync(buffer: snapshot, width: w, height: h, useColor: useColorSnapshot)
    }

    private func renderImageAsync(buffer: [Float], width: Int, height: Int, useColor: Bool) {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let cg: CGImage?
            if useColor {
                cg = ImageUtils.makeARGBFFFFCGImage(buffer: buffer, width: width, height: height)
            } else {
                cg = ImageUtils.makeGrascaleCGImage(buffer: buffer, width: width, height: height)
            }

            guard let cg else { return }
            let image = Image(decorative: cg, scale: 1.0)

            await MainActor.run {
                self.outputImage = image
            }
        }
    }

    private func makeOutputImage(from buffer: [Float]) -> Image? {
        let cg: CGImage?
        if useColor {
            cg = ImageUtils.makeARGBFFFFCGImage(buffer: buffer, width: imageWidth, height: imageHeight)
        } else {
            cg = ImageUtils.makeGrascaleCGImage(buffer: buffer, width: imageWidth, height: imageHeight)
        }

        guard let cg else { return nil }
        return Image(decorative: cg, scale: 1.0)
    }

    private static func boxBlurKernel(size: Int) -> [Float] {
        precondition(size % 2 == 1, "kernelSize must be odd")
        let v: Float = 1.0 / Float(size * size)
        return Array(repeating: v, count: size * size)
    }
}
