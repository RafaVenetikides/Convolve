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
    @Published var cursorX: Int = 0
    @Published var cursorY: Int = 0
    @Published var isRunning: Bool = false

    @Published var pixelsPerTick: Double = 120

    @Published private(set) var imageWidth: Int = 1
    @Published private(set) var imageHeight: Int = 1

    let kernelSize: Int = 31

    private var engine: ConvolutionEngine?
    private var timer: Timer?

    private lazy var blurKernel: [Float] = Self.boxBlurKernel(size: kernelSize)

    func setup() {
        guard let loaded = ImageUtils.loadGrayscaleBuffer(assetName: "miku") else { return }
        originalUIImage = loaded.original
        imageWidth = loaded.width
        imageHeight = loaded.height

        engine = ConvolutionEngine(
            input: loaded.buffer,
            width: imageWidth,
            height: imageHeight,
            kernel: blurKernel,
            kernelSize: kernelSize
        )

        updateOutputImage()
        cursorX = 0
        cursorY = 0
    }

    func togglePlay() {
        isRunning.toggle()
        if isRunning { startTimer() } else { stopTimer() }
    }

    func stepOnce() {
        guard let engine else { return }
        engine.step(pixels: Int(pixelsPerTick))
        cursorX = engine.x
        cursorY = engine.y
        updateOutputImage()
    }

    func reset() {
        stopTimer()
        isRunning = false
        engine?.reset()
        cursorX = 0
        cursorY = 0
        updateOutputImage()
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
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
        guard let engine else { return }
        if engine.isFinished {
            stopTimer()
            isRunning = false
            return
        }

        engine.step(pixels: Int(pixelsPerTick))
        cursorX = engine.x
        cursorY = engine.y

        updateOutputImage()
    }

    private func updateOutputImage() {
        guard let engine else { return }
        guard let cg = ImageUtils.makeGrascaleCGImage(buffer: engine.output, width: imageWidth, height: imageHeight) else { return }
        outputImage = Image(decorative: cg, scale: 1.0)
    }

    private static func boxBlurKernel(size: Int) -> [Float] {
        precondition(size % 2 == 1, "kernelSize must be odd")
        let v: Float = 1.0 / Float(size * size)
        return Array(repeating: v, count: size * size)
    }
}
