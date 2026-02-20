//
//  FeatureMapsViewModel.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 19/02/26.
//

import SwiftUI

@MainActor
final class FeatureMapsViewModel: ObservableObject {
    let engine = ConvolutionEngine()

    var outputs: [Image?] { engine.outputs }
    var kernels: [KernelSpec] = []

    init() {
        kernels = Self.makeKernels()
    }

    func setup(assetName: String) {
        engine.pixelsPerTick = 25
        engine.renderFPS = 15

        engine.configure(
            assetName: assetName,
            mode: .grayscale,
            kernels: kernels
        ) { k, a in
            let blurLike =
                k.name.contains("Blur") || k.name.contains("Gaussian")
                || k.name.contains("Identity") || k.name.contains("Sharpen")
            if blurLike {
                return a.map { min(max($0, 0), 1) }
            } else {
                var maxAbs: Float = 0
                for v in a { maxAbs = max(maxAbs, abs(v)) }
                let inv = maxAbs > 0 ? 1.0 / maxAbs : 1.0
                return a.map { abs($0) * inv }
            }
        }
    }

    func start() { engine.start() }
    func stop() { engine.stop() }

    private static func makeKernels() -> [KernelSpec] {
        let identity = KernelSpec(
            name: "Identity (3x3)",
            size: 3,
            weights: [0, 0, 0, 0, 1, 0, 0, 0, 0]
        )
        let box = KernelSpec(
            name: "Box Blur (3x3)",
            size: 3,
            weights: Array(repeating: 1.0 / 9.0, count: 9)
        )
        let sharpen = KernelSpec(
            name: "Sharpen (3x3)",
            size: 3,
            weights: [0, -1, 0, -1, 5, -1, 0, -1, 0]
        )
        let edge = KernelSpec(
            name: "Edge (3x3)",
            size: 3,
            weights: [-1, -1, -1, -1, 8, -1, -1, -1, -1]
        )
        let sx = KernelSpec(
            name: "Sobel X (3x3)",
            size: 3,
            weights: [-1, 0, 1, -2, 0, 2, -1, 0, 1]
        )
        let sy = KernelSpec(
            name: "Sobel Y (3x3)",
            size: 3,
            weights: [-1, -2, -1, 0, 0, 0, 1, 2, 1]
        )

        let g5: [Float] = [
            1, 4, 6, 4, 1,
            4, 16, 24, 16, 4,
            6, 24, 36, 24, 6,
            4, 16, 24, 16, 4,
            1, 4, 6, 4, 1,
        ]
        let sum = g5.reduce(0, +)
        let gaussian5 = KernelSpec(
            name: "Gaussian (5x5)",
            size: 5,
            weights: g5.map { $0 / sum }
        )

        return [identity, box, sharpen, edge, sx, sy, gaussian5]
    }
}
