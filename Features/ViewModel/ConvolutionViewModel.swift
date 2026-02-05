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

    @Published var selectedPreset: KernelPreset = .boxBlur

    @Published var cursorX: Int = 0
    @Published var cursorY: Int = 0
    @Published var isRunning: Bool = false

    @Published var pixelsPerTick: Double = 600

    @Published private(set) var imageWidth: Int = 1
    @Published private(set) var imageHeight: Int = 1

    var kernelSize: Int { selectedPreset.size }

    private let renderFPS: Double = 15

    private var kernel: [Float] { selectedPreset.makeKernel() }

    private var input: [Float] = []
    private var fullOutput: [Float] = []
    private var revealedOutput: [Float] = []

    //    private var engine: ConvolutionEngine?
    private var timer: Timer?
    private var computeTask: Task<Void, Never>?
    private var isComputing = false

    private var lastRenderTime: CFTimeInterval = 0

    func setup(assetName: String) {
        guard let loaded = ImageUtils.loadGrayscaleBuffer(assetName: assetName)
        else { return }

        originalUIImage = loaded.original
        imageWidth = loaded.width
        imageHeight = loaded.height

        input = loaded.buffer
        fullOutput.removeAll(keepingCapacity: true)

        revealedOutput = Array(repeating: 0, count: imageWidth * imageHeight)

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
        revealedOutput = Array(repeating: 0, count: imageWidth * imageHeight)
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
        revealedOutput = Array(repeating: 0, count: imageWidth * imageHeight)
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

        timer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 60.0,
            repeats: true
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.tick()
            }
        }
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

    private func revealOutput(upToIndexExclusive index: Int) {
        let maxIdx = imageWidth * imageHeight - 1
        let clamped = min(max(index, 0), maxIdx)

        let count = clamped + 1
        guard count > 0 else { return }
        revealedOutput.replaceSubrange(0..<count, with: fullOutput[0..<count])
    }

    private func startComputeIfNeeded() {
        guard !isComputing, fullOutput.isEmpty, !input.isEmpty else { return }

        isComputing = true

        let inputSnapshot = input
        let w = imageWidth
        let h = imageHeight
        let k = kernel
        let ks = kernelSize

        computeTask?.cancel()
        computeTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let out = AccelerateConvolution.convolvePlanarF(
                input: inputSnapshot,
                width: w,
                height: h,
                kernel: k,
                kernelSize: ks
            )

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

        renderImageAsync(buffer: snapshot, width: w, height: h)
    }

    private func renderImageAsync(buffer: [Float], width: Int, height: Int) {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            guard
                let cg = ImageUtils.makeGrascaleCGImage(
                    buffer: buffer,
                    width: width,
                    height: height
                )
            else { return }
            let image = Image(decorative: cg, scale: 1.0)

            await MainActor.run {
                self.outputImage = image
            }
        }
    }

    private func makeOutputImage(from buffer: [Float]) -> Image? {
        guard
            let cg = ImageUtils.makeGrascaleCGImage(
                buffer: buffer,
                width: imageWidth,
                height: imageHeight
            )
        else { return nil }
        return Image(decorative: cg, scale: 1.0)
    }

    private static func boxBlurKernel(size: Int) -> [Float] {
        precondition(size % 2 == 1, "kernelSize must be odd")
        let v: Float = 1.0 / Float(size * size)
        return Array(repeating: v, count: size * size)
    }
}
