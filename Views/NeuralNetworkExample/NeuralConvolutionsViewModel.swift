//
//  NeuralConvolutionsViewModel.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 18/02/26.
//

import SwiftUI

@MainActor
final class NeuralConvolutionsViewModel: ObservableObject {
    @Published var originalUIImage: UIImage?

    @Published var outEdge: Image?
    @Published var outSobelX: Image?
    @Published var outSobelY: Image?

    @Published var cursorX: Int = 0
    @Published var cursorY: Int = 0
    @Published var isRunning: Bool = false

    @Published private(set) var imageWidth: Int = 1
    @Published private(set) var imageHeight: Int = 1

    var pixelsPerTick: Double = 2

    private let renderFPS: Double = 15

    private var input: [Float] = []

    private var fullEdge: [Float] = []
    private var fullX: [Float] = []
    private var fullY: [Float] = []

    private var revealedEdge: [Float] = []
    private var revealedX: [Float] = []
    private var revealedY: [Float] = []

    private var timer: Timer?
    private var computeTask: Task<Void, Never>?
    private var isComputing = false
    private var lastRenderTime: CFTimeInterval = 0

    let kernelSize: Int = 3

    private let kEdge: [Float] = [
        -1, -1, -1,
        -1,  8, -1,
        -1, -1, -1,
    ]

    private let kSobelX: [Float] = [
        -1, 0, 1,
        -2, 0, 2,
        -1, 0, 1,
    ]

    private let kSobelY: [Float] = [
        -1, -2, -1,
         0,  0,  0,
         1,  2,  1
    ]

    func setup(assetName: String) {
        guard let loaded = ImageUtils.loadGrayscaleBuffer(assetName: assetName) else { return }

        originalUIImage = loaded.original
        imageWidth = loaded.width
        imageHeight = loaded.height

        input = loaded.buffer

        fullEdge.removeAll(keepingCapacity: true)
        fullX.removeAll(keepingCapacity: true)
        fullY.removeAll(keepingCapacity: true)

        stop()
        cursorX = 0
        cursorY = 0
        isComputing = false
        lastRenderTime = 0

        let count = imageWidth * imageHeight
        revealedEdge = Array(repeating: 0, count: count)
        revealedX = Array(repeating: 0, count: count)
        revealedY = Array(repeating: 0, count: count)

        outEdge = makeOutputImage(from: revealedEdge)
        outSobelX = makeOutputImage(from: revealedX)
        outSobelY = makeOutputImage(from: revealedY)
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        startComputeIfNeeded()
        startTimer()
    }

    func stop() {
        stopTimer()
        computeTask?.cancel()
        computeTask = nil
        isRunning = false
    }

    private func startTimer() {
        stopTimer()
        lastRenderTime = 0

        let t = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.tick() }
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
            if fullEdge.isEmpty && isComputing { return }

            if !fullEdge.isEmpty {
                let pixelCount = imageWidth * imageHeight
                revealOutput(upToIndexExclusive: pixelCount)
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

        if idx >= maxIdx {
            cursorX = 0
            cursorY = imageHeight
            return
        }

        cursorY = idx / imageWidth
        cursorX = idx % imageWidth
    }

    private func revealIfPossible() {
        guard !fullEdge.isEmpty else { return }
        revealOutput(upToIndexExclusive: cursorY * imageWidth + cursorX)
    }

    private func revealOutput(upToIndexExclusive pixelIndex: Int) {
        let pixelCount = imageWidth * imageHeight
        guard pixelCount > 0 else { return }
        let clampedPixel = min(max(pixelIndex, 0), pixelCount - 1)
        let count = clampedPixel + 1
        guard count > 0 else { return }

        revealedEdge.replaceSubrange(0..<count, with: fullEdge[0..<count])
        revealedX.replaceSubrange(0..<count, with: fullX[0..<count])
        revealedY.replaceSubrange(0..<count, with: fullY[0..<count])
    }

    private func startComputeIfNeeded() {
        guard !isComputing, fullEdge.isEmpty, !input.isEmpty else { return }
        isComputing = true

        let inputSnapshot = input
        let w = imageWidth
        let h = imageHeight

        computeTask?.cancel()
        computeTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let edgeRaw = AccelerateConvolution.convolvePlanarFGrayscale(
                input: inputSnapshot,
                width: w,
                height: h,
                kernel: self.kEdge,
                kernelSize: self.kernelSize
            )

            let xRaw = AccelerateConvolution.convolvePlanarFGrayscale(
                input: inputSnapshot,
                width: w,
                height: h,
                kernel: self.kSobelX,
                kernelSize: self.kernelSize
            )

            let yRaw = AccelerateConvolution.convolvePlanarFGrayscale(
                input: inputSnapshot,
                width: w,
                height: h,
                kernel: self.kSobelY,
                kernelSize: self.kernelSize
            )

            func normalize(_ a: [Float]) -> [Float] {
                var maxAbs: Float = 0
                for v in a {
                    let av = abs(v)
                    if av > maxAbs { maxAbs = av }
                }
                let inv = maxAbs > 0 ? (1.0 / maxAbs) : 1.0
                return a.map { abs($0) * inv }
            }

            let edge = normalize(edgeRaw)
            let x = normalize(xRaw)
            let y = normalize(yRaw)

            await MainActor.run {
                self.fullEdge = edge
                self.fullX = x
                self.fullY = y
                self.isComputing = false

                self.revealOutput(upToIndexExclusive: self.cursorY * self.imageWidth + self.cursorX)
            }
        }
    }

    private func scheduleRenderIfNeeded() {
        let now = CACurrentMediaTime()
        guard now - lastRenderTime >= (1.0 / renderFPS) else { return }
        lastRenderTime = now

        let w = imageWidth
        let h = imageHeight

        let e = revealedEdge
        let x = revealedX
        let y = revealedY

        renderImagesAsync(edge: e, sobelX: x, sobelY: y, width: w, height: h)
    }

    private func renderImagesAsync(edge: [Float], sobelX: [Float], sobelY: [Float], width: Int, height: Int) {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let cgE = ImageUtils.makeGrascaleCGImage(buffer: edge, width: width, height: height)
            let cgX = ImageUtils.makeGrascaleCGImage(buffer: sobelX, width: width, height: height)
            let cgY = ImageUtils.makeGrascaleCGImage(buffer: sobelY, width: width, height: height)

            guard let cgE, let cgX, let cgY else { return }

            let imgE = Image(decorative: cgE, scale: 1.0)
            let imgX = Image(decorative: cgX, scale: 1.0)
            let imgY = Image(decorative: cgY, scale: 1.0)

            await MainActor.run {
                self.outEdge = imgE
                self.outSobelX = imgX
                self.outSobelY = imgY
            }
        }
    }

    private func makeOutputImage(from buffer: [Float]) -> Image? {
        guard let cg = ImageUtils.makeGrascaleCGImage(buffer: buffer, width: imageWidth, height: imageHeight) else { return nil }
        return Image(decorative: cg, scale: 1.0)
    }
}
