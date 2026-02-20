//
//  NeuralConvolutionsViewModel.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 18/02/26.
//

import SwiftUI
import Combine

@MainActor
final class NeuralConvolutionsViewModel: ObservableObject {
    private let engine = ConvolutionEngine()
    private var bag = Set<AnyCancellable>()

    @Published var originalUIImage: UIImage?
    @Published var outputs: [Image?] = []

    @Published var cursorX: Int = 0
    @Published var cursorY: Int = 0
    @Published private(set) var imageWidth: Int = 1
    @Published private(set) var imageHeight: Int = 1

    let kernelSize: Int = 3

    var outEdge: Image?  { outputs.indices.contains(0) ? outputs[0] : nil }
    var outSobelX: Image? { outputs.indices.contains(1) ? outputs[1] : nil }
    var outSobelY: Image? { outputs.indices.contains(2) ? outputs[2] : nil }

    private let kernels: [KernelSpec] = [
        .init(name: "Edge", size: 3, weights: [-1,-1,-1, -1,8,-1, -1,-1,-1]),
        .init(name: "Sobel X", size: 3, weights: [-1,0,1, -2,0,2, -1,0,1]),
        .init(name: "Sobel Y", size: 3, weights: [-1,-2,-1, 0,0,0, 1,2,1]),
    ]

    init() {
        bind()
    }

    private func bind() {
        engine.$originalUIImage.assign(to: &$originalUIImage)
        engine.$outputs.assign(to: &$outputs)
        engine.$cursorX.assign(to: &$cursorX)
        engine.$cursorY.assign(to: &$cursorY)
        engine.$imageWidth.assign(to: &$imageWidth)
        engine.$imageHeight.assign(to: &$imageHeight)
    }

    func setup(assetName: String) {
        engine.pixelsPerTick = 25
        engine.renderFPS = 15

        engine.configure(
            assetName: assetName,
            mode: .grayscale,
            kernels: kernels,
            normalizer: { _, a in
                var maxAbs: Float = 0
                for v in a { maxAbs = max(maxAbs, abs(v)) }
                let inv = maxAbs > 0 ? 1.0 / maxAbs : 1.0
                return a.map { abs($0) * inv }
            }
        )
    }

    func start() { engine.start() }
    func stop() { engine.stop() }
}
