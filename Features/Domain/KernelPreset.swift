//
//  KernelPreset.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 05/02/26.
//

import Foundation

enum KernelPreset: String, CaseIterable, Identifiable {
    case boxBlur = "Box Blur"
    case gaussianBlur = "Gaussian Blur"
    case sharpen = "Sharpen"
    case edgeDetect = "Edge Detect"
    case sobelX = "Sobel X"
    case sobelY = "Sobel Y"
    case laplacian = "Laplacian"

    var id: String { rawValue }

    var isBlur: Bool {
        switch self {
        case .boxBlur, .gaussianBlur: return true
        default: return false
        }
    }

    func kernelSize(width: Int, height: Int, intensity: BlurIntensity) -> Int {
        switch self {
        case .boxBlur, .gaussianBlur:
            let minSide = max(1, min(width, height))
            let raw = Int(Double(minSide) * intensity.fractionOfMinSide)

            let clamped = min(max(raw, 7), 151)

            return (clamped % 2 == 1) ? clamped : (clamped + 1)

        case .sharpen, .edgeDetect, .sobelX, .sobelY, .laplacian:
            return 3
        }
    }

    func makeKernel(size: Int) -> [Float] {
        switch self {
        case .boxBlur:
            return Self.boxBlur(size: size)
        case .gaussianBlur:
            return Self.gaussianBlur(size: size, sigma: Float(size) / 6.0)
        case .sharpen:
            return [
                0, -1, 0,
                -1, 5, -1,
                0, -1, 0
            ]
        case .edgeDetect:
            return [
                -1, -1, -1,
                 -1, 8, -1,
                 -1, -1, -1
            ]
        case .sobelX:
            return [
                -1, 0, 1,
                 -2, 0, 2,
                 -1, 0, 1
            ]
        case .sobelY:
            return [
                -1, -2, -1,
                 0, 0, 0,
                 1, 2, 1
            ]
        case .laplacian:
            return [
                0, 1, 0,
                1, -4, 1,
                0, 1, 0
            ]
        }
    }

    private static func boxBlur(size: Int) -> [Float] {
        precondition(size % 2 == 1)
        let v: Float = 1.0 / Float(size * size)
        return Array(repeating: v, count: size * size)
    }

    private static func gaussianBlur(size: Int, sigma: Float) -> [Float] {
        precondition(size % 2 == 1)
        let r = size / 2

        var k = [Float](repeating: 0, count: size * size)
        var sum: Float = 0

        for y in -r...r {
            for x in -r...r {
                let fx = Float(x)
                let fy = Float(y)
                let v = exp(-(fx*fx + fy*fy) / (2 * sigma * sigma))
                let idx = (y + r) * size + (x + r)
                k[idx] = v
                sum += v
            }
        }

        if sum > 0 {
            for i in 0..<k.count { k[i] /= sum }
        }
        return k
    }
}
