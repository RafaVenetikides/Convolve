//
//  ConvolutionEngine.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 04/02/26.
//

import CoreGraphics
import Foundation

final class ConvolutionEngine {
    let width: Int
    let height: Int
    let kernelSize: Int
    let kernel: [Float]

    private(set) var input: [Float]
    private(set) var output: [Float]

    private(set) var x: Int = 0
    private(set) var y: Int = 0
    private let radius: Int

    init(input: [Float], width: Int, height: Int, kernel: [Float], kernelSize: Int) {
        self.input = input
        self.width = width
        self.height = height
        self.kernel = kernel
        self.kernelSize = kernelSize
        self.output = Array(repeating: 0, count: width * height)
        self.radius = kernelSize / 2
    }

    func reset() {
        output = Array(repeating: 0, count: width * height)
        x = 0
        y = 0
    }

    var isFinished: Bool { y >= height }

    @discardableResult
    func stepOnePixel() -> Bool {
        guard !isFinished else { return false}

        let idx = y * width + x
        output[idx] = convolveAt(x: x, y: y)

        x += 1
        if x >= width {
            x = 0
            y += 1
        }
        return true
    }

    func step(pixels count: Int) {
        guard count > 0 else { return }
        for _ in 0..<count {
            if !stepOnePixel() { break }
        }
    }

    private func sampleClamped(x: Int, y: Int) -> Float {
        let cx = min(max(x, 0), width - 1)
        let cy = min(max(y, 0), height - 1)
        return input[cy * width + cx]
    }

    private func convolveAt(x: Int, y: Int) -> Float {
        var sum: Float = 0

        for ky in 0..<kernelSize {
            for kx in 0..<kernelSize {
                let ix = x + (kx - radius)
                let iy = y + (ky - radius)
                let pixel = sampleClamped(x: ix, y: iy)
                let w = kernel[ky * kernelSize + kx]
                sum += pixel * w
            }
        }

        return min(max(sum, 0), 1)
    }
}
