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
    @Published var isFinished = false

    @Published private(set) var imageWidth: Int = 1
    @Published private(set) var imageHeight: Int = 1

    @Published var useColor: Bool = true
    @Published var selectedPreset: KernelPreset = .boxBlur
    @Published var blurIntensity: BlurIntensity = .medium
    @Published var pixelsPerTick: Double = 100

    @Published private var customKernel: [Float]? = nil
    @Published private var customKernelSize: Int? = nil

    let engine = ConvolutionEngine()
    private var currentAssetName: String?

    private enum Source {
        case asset(String)
        case photo(Data)
    }

    private var currentSource: Source?

    init() {
        bind()
    }

    private func bind() {
        engine.$originalUIImage.assign(to: &$originalUIImage)
        engine.$cursorX.assign(to: &$cursorX)
        engine.$cursorY.assign(to: &$cursorY)
        engine.$isRunning.assign(to: &$isRunning)
        engine.$isFinished.assign(to: &$isFinished)
        engine.$imageWidth.assign(to: &$imageWidth)
        engine.$imageHeight.assign(to: &$imageHeight)

        engine.$outputs
            .map { $0.first ?? nil }
            .assign(to: &$outputImage)
    }

    var kernelSize: Int {
        if let customKernelSize { return customKernelSize }
        return selectedPreset.kernelSize(
            width: imageWidth,
            height: imageHeight,
            intensity: blurIntensity
        )
    }

    var kernelWeights: [Float] {
        if let customKernel { return customKernel }
        return selectedPreset.makeKernel(size: kernelSize)
    }

    var kernelSpec: KernelSpec {
        KernelSpec(
            name: selectedPreset.rawValue,
            size: kernelSize,
            weights: kernelWeights
        )
    }

    private var mode: PixelMode { useColor ? .argbffff : .grayscale }

    func setup(assetName: String) {
        currentSource = .asset(assetName)
        engine.pixelsPerTick = pixelsPerTick
        engine.configure(
            assetName: assetName,
            mode: mode,
            kernels: [kernelSpec]
        )
    }

    func setup(imageData: Data) {
        currentSource = .photo(imageData)
        engine.pixelsPerTick = pixelsPerTick
        engine.configure(
            imageData: imageData,
            mode: mode,
            kernels: [kernelSpec]
        )
    }

    func togglePlay() {
        isRunning ? stop() : start()
    }

    func start() {
        engine.pixelsPerTick = pixelsPerTick
        engine.start()
    }

    func stop() {
        engine.stop()
    }

    func stepOnce() {
        engine.pixelsPerTick = pixelsPerTick
        engine.stepOnce()
    }

    func reset() {
        engine.reset()
    }

    func primaryAction() {
        if isFinished {
            reset()
            start()
            return
        }
        togglePlay()
    }

    func setPreset(_ preset: KernelPreset) {
        selectedPreset = preset
        reconfigureKeepingAsset()
    }

    func setBlurIntensity(_ intensity: BlurIntensity) {
        blurIntensity = intensity
        guard selectedPreset.isBlur else { return }
        reconfigureKeepingAsset()
    }

    func setCustomKernel(size: Int, kernel: [Float]) {
        precondition(kernel.count == size * size)
        customKernelSize = size
        customKernel = kernel
        reconfigureKeepingAsset()
    }

    func clearCustomKernel() {
        customKernelSize = nil
        customKernel = nil
        reconfigureKeepingAsset()
    }

    func updateSpeed(_ v: Double) {
        pixelsPerTick = v
        engine.pixelsPerTick = v
    }

    private func reconfigureKeepingAsset() {
        guard let source = currentSource else { return }

        let wasRunning = isRunning
        stop()

        switch source {
        case .asset(let assetName):
            setup(assetName: assetName)
        case .photo(let data):
            setup(imageData: data)
        }

        if wasRunning { start() }
    }
}
