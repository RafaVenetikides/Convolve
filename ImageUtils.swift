//
//  ImageUtils.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 04/02/26.
//

import UIKit
import CoreGraphics

enum ImageUtils {
    static func loadGrayscaleBuffer(assetName: String) -> (buffer: [Float], width: Int, height: Int, original: UIImage)? {
        guard let uiImage = UIImage(named: assetName),
              let cgImage = uiImage.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var rgba = [UInt8](repeating: 0, count: height * bytesPerRow)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: &rgba,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var gray = [Float](repeating: 0, count: width * height)
        gray.withUnsafeMutableBufferPointer { grayPtr in
            for y in 0..<height {
                for x in 0..<width {
                    let i = y * bytesPerRow + x * bytesPerPixel
                    let r = Float(rgba[i]) / 255.0
                    let g = Float(rgba[i + 1]) / 255.0
                    let b = Float(rgba[i + 2]) / 255.0
                    let lum = 0.2126*r + 0.7152*g + 0.0722*b
                    grayPtr[y * width + x] = lum
                }
            }
        }

        return (gray, width, height, uiImage)
    }

    static func makeGrascaleCGImage(buffer: [Float], width: Int, height: Int) -> CGImage? {
        var bytes = [UInt8](repeating: 0, count: width * height)
        for i in 0..<bytes.count {
            let v = min(max(buffer[i], 0), 1)
            bytes[i] = UInt8(v * 255.0)
        }

        let cfData = CFDataCreate(nil, bytes, bytes.count)!
        let provider = CGDataProvider(data: cfData)!

        let colorSpace = CGColorSpaceCreateDeviceGray()
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: 0),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}
