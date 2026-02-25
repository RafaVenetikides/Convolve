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

    var description: String {
        switch self {
        case .boxBlur:
            return "Box Blur kernel replaces the color of the pixel with the average of the the pixels surrounding it, resulting in a blur, with smooth details and noise reduction"
        case .gaussianBlur:
            return "Gaussian blur alsho smooths the image, but it uses a higher weight in the central pixel. This results in a blur that looks more natural and less \"blocky\""
        case .sharpen:
            return "Sharpen kernel increases the contrast around edges to make details look clearer, enhancing fine textures and outlines."
        case .edgeDetect:
            return "Edge detection highlights where the image changes sharply, highlighting the edged of objects in the image, while flat areas look darker"
        case .sobelX:
            return "Sobel X detects vertical edges on the image. It highlights areas where pixels change strongly in the horizontal direction."
        case .sobelY:
            return "Sobel Y detects horizontal edges on the image. It measures changes from top to bottom, highlighting pixels the change strongly in the vertical direction"
        case .laplacian:
            return "Laplacian is an kernal that looks for changes in all directions (not just X and Y). Compared to Edge Detect, it tends to produce a thinner, more detailed outlines."
        }
    }

    func kernelSize(width: Int, height: Int, intensity: BlurIntensity) -> Int {
        switch self {
        case .boxBlur, .gaussianBlur:
            let minSide = max(1, min(width, height))
            let raw = Int(Double(minSide) * intensity.fractionOfMinSide)

            let clamped = min(max(raw, 3), 151)

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
