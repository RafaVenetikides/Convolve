//
//  ConvolutionTypes.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 19/02/26.
//

import SwiftUI

enum PixelMode: Equatable, Sendable {
    case grayscale
    case argbffff

    var stride: Int { self == .argbffff ? 4 : 1}
}

struct KernelSpec: Identifiable, Equatable, Sendable {
    let id = UUID()
    let name: String
    let size: Int
    let weights: [Float]
}
