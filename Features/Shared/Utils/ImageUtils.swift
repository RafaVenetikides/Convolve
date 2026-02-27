//
//  ImageUtils.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 04/02/26.
//

import CoreGraphics
import UIKit

enum ImageUtils {
    static func loadGrayscaleBuffer(assetName: String) -> (
        buffer: [Float], width: Int, height: Int, original: UIImage
    )? {
        guard let uiImage = UIImage(named: assetName),
            let cgImage = uiImage.cgImage
        else { return nil }

        let width = cgImage.width
        let height = cgImage.height

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var rgba = [UInt8](repeating: 0, count: height * bytesPerRow)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard
            let ctx = CGContext(
                data: &rgba,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return nil }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var gray = [Float](repeating: 0, count: width * height)
        gray.withUnsafeMutableBufferPointer { grayPtr in
            for y in 0..<height {
                for x in 0..<width {
                    let i = y * bytesPerRow + x * bytesPerPixel
                    let r = Float(rgba[i]) / 255.0
                    let g = Float(rgba[i + 1]) / 255.0
                    let b = Float(rgba[i + 2]) / 255.0
                    let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
                    grayPtr[y * width + x] = lum
                }
            }
        }

        return (gray, width, height, uiImage)
    }

    static func makeGrascaleCGImage(buffer: [Float], width: Int, height: Int)
        -> CGImage?
    {
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

    static func loadARGBFFFFBuffer(assetName: String) -> (
        buffer: [Float], width: Int, height: Int, original: UIImage
    )? {
        guard let uiImage = UIImage(named: assetName),
            let cgImage = uiImage.cgImage
        else { return nil }

        let width = cgImage.width
        let height = cgImage.height

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var rgba = [UInt8](repeating: 0, count: height * bytesPerRow)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard
            let ctx = CGContext(
                data: &rgba,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return nil }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var argb = [Float](repeating: 0, count: width * height * 4)
        argb.withUnsafeMutableBufferPointer { argbPtr in
            for y in 0..<height {
                for x in 0..<width {
                    let i = y * bytesPerRow + x * bytesPerPixel

                    let r = Float(rgba[i]) / 255.0
                    let g = Float(rgba[i + 1]) / 255.0
                    let b = Float(rgba[i + 2]) / 255.0
                    let a = Float(rgba[i + 3]) / 255.0

                    let o = (y * width + x) * 4
                    argbPtr[o + 0] = a
                    argbPtr[o + 1] = r
                    argbPtr[o + 2] = g
                    argbPtr[o + 3] = b
                }
            }
        }

        return (argb, width, height, uiImage)
    }

    static func makeARGBFFFFCGImage(buffer: [Float], width: Int, height: Int)
        -> CGImage?
    {
        precondition(buffer.count == width * height * 4)

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel

        var rgba = [UInt8](repeating: 0, count: height * bytesPerRow)

        for p in 0..<(width * height) {
            let i = p * 4
            let a = min(max(buffer[i + 0], 0), 1)
            let r = min(max(buffer[i + 1], 0), 1)
            let g = min(max(buffer[i + 2], 0), 1)
            let b = min(max(buffer[i + 3], 0), 1)

            let o = p * 4
            rgba[o + 0] = UInt8(r * 255.0)
            rgba[o + 1] = UInt8(g * 255.0)
            rgba[o + 2] = UInt8(b * 255.0)
            rgba[o + 3] = UInt8(a * 255.0)
        }

        let cfData = CFDataCreate(nil, rgba, rgba.count)!
        let provider = CGDataProvider(data: cfData)!

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }

    private static func decodeUIImage(from imageData: Data) -> (
        ui: UIImage, cg: CGImage
    )? {
        if let ui = UIImage(data: imageData), let cg = ui.cgImage {
            return (ui, cg)
        }

        guard let src = CGImageSourceCreateWithData(imageData as CFData, nil),
            let cg = CGImageSourceCreateImageAtIndex(src, 0, nil)
        else {
            return nil
        }

        let ui = UIImage(cgImage: cg)
        return (ui, cg)
    }

    static func loadGrayscaleBuffer(imageData: Data) -> (
        buffer: [Float], width: Int, height: Int, original: UIImage
    )? {
        guard let decoded = decodeUIImage(from: imageData) else { return nil }
        let uiImage = decoded.ui
        let cgImage = decoded.cg

        let width = cgImage.width
        let height = cgImage.height

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var rgba = [UInt8](repeating: 0, count: height * bytesPerRow)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard
            let ctx = CGContext(
                data: &rgba,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return nil }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var gray = [Float](repeating: 0, count: width * height)
        gray.withUnsafeMutableBufferPointer { grayPtr in
            for y in 0..<height {
                for x in 0..<width {
                    let i = y * bytesPerRow + x * bytesPerPixel
                    let r = Float(rgba[i]) / 255.0
                    let g = Float(rgba[i + 1]) / 255.0
                    let b = Float(rgba[i + 2]) / 255.0
                    let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
                    grayPtr[y * width + x] = lum
                }
            }
        }

        return (gray, width, height, uiImage)
    }

    static func loadARGBFFFFBuffer(imageData: Data) -> (
        buffer: [Float], width: Int, height: Int, original: UIImage
    )? {
        guard let decoded = decodeUIImage(from: imageData) else { return nil }
        let uiImage = decoded.ui
        let cgImage = decoded.cg

        let width = cgImage.width
        let height = cgImage.height

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var rgba = [UInt8](repeating: 0, count: height * bytesPerRow)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard
            let ctx = CGContext(
                data: &rgba,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return nil }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var argb = [Float](repeating: 0, count: width * height * 4)
        argb.withUnsafeMutableBufferPointer { argbPtr in
            for y in 0..<height {
                for x in 0..<width {
                    let i = y * bytesPerRow + x * bytesPerPixel

                    let r = Float(rgba[i]) / 255.0
                    let g = Float(rgba[i + 1]) / 255.0
                    let b = Float(rgba[i + 2]) / 255.0
                    let a = Float(rgba[i + 3]) / 255.0

                    let o = (y * width + x) * 4
                    argbPtr[o + 0] = a
                    argbPtr[o + 1] = r
                    argbPtr[o + 2] = g
                    argbPtr[o + 3] = b
                }
            }
        }

        return (argb, width, height, uiImage)
    }
}
