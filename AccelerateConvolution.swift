//
//  AccelerateConvolution.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 05/02/26.
//

import Accelerate

enum AccelerateConvolution {
    static func convolvePlanarF(input: [Float], width: Int, height: Int, kernel: [Float], kernelSize: Int) -> [Float] {
        precondition(input.count == width * height)
        precondition(kernel.count == kernelSize * kernelSize)
        precondition(kernelSize % 2 == 1)

        var src = input
        var dst = [Float](repeating: 0, count: width * height)

        src.withUnsafeMutableBufferPointer { srcPtr in
            dst.withUnsafeMutableBufferPointer { dstPtr in
                var srcBuf = vImage_Buffer(
                    data: srcPtr.baseAddress!,
                    height: vImagePixelCount(height),
                    width: vImagePixelCount(width),
                    rowBytes: width * MemoryLayout<Float>.size
                )

                var dstBuf = vImage_Buffer(
                    data: dstPtr.baseAddress!,
                    height: vImagePixelCount(height),
                    width: vImagePixelCount(width),
                    rowBytes: width * MemoryLayout<Float>.size
                )

                var k = kernel

                let err = vImageConvolve_PlanarF(
                    &srcBuf,
                    &dstBuf,
                    nil,
                    0,
                    0,
                    &k,
                    UInt32(kernelSize),
                    UInt32(kernelSize),
                    0,
                    vImage_Flags(kvImageEdgeExtend)
                )

                precondition(err == kvImageNoError)
            }
        }

        vDSP_vclip(dst, 1, [0], [1], &dst, 1, vDSP_Length(dst.count))
        return dst
    }
}
