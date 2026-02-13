//
//  ConvolutionAnimationViewModel.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 12/02/26.
//

import SwiftUI

@MainActor
final class ConvolutionAnimationViewModel: ObservableObject {
    var stepText: AttributedString {
        let raw: String

        switch stage {
        case .original:
            raw =
                "We will take a look at a much simpler version of convolution called discrete convolution. For this, I want you to imagine a pair of lists of numbers, in which we will be applying the convolution."
        case .shiftReady:
            if shift == -1 {
                raw = "1\\. First we **flip** the second list of numbers"
            } else if shift == 0 {
                raw =
                    "2\\. We **multiply** the first and last operators from the lists, and **add** all the results"
            } else {
                raw =
                    "3\\. Then we **shift** the lists and repeat the second step until it's over"
            }
        }

        return (try? AttributedString(markdown: raw)) ?? AttributedString(raw)
    }

    var hasFinished = false

    enum Stage {
        case original
        case shiftReady
    }

    let a: [Int]
    let b: [Int]

    var convResult: [Int] { a.convolve(with: b) }

    @Published var shift: Int = -1
    @Published var highlightedPairs: [(Int, Int)] = []

    @Published var stage: Stage = .original
    @Published var bIsReversed: Bool = false
    @Published var bRotationDeg: Double = 0

    let cellPitch: CGFloat = 54
    let rowSpacingY: CGFloat = 18

    init(a: [Int] = [3, 4, 5], b: [Int] = [8, 9, 10]) {
        self.a = a
        self.b = b
    }

    func bOffsetX() -> CGFloat {
        guard shift >= 0 else { return 0 }
        let m = b.count
        let deltaCells = shift - (m - 1)
        return CGFloat(deltaCells) * cellPitch
    }

    func expressionForCurrentShift() -> String {
        let pairs = alignedPairs(shift: shift)
        return pairs.map { (iA, iBrev) in
            let vA = a[iA]
            let vB = b.reversed()[iBrev]
            return "\(vA)·\(vB)"
        }.joined(separator: " + ")
    }

    private func alignedPairs(shift: Int) -> [(Int, Int)] {
        let n = a.count
        let m = b.count
        var out: [(Int, Int)] = []
        for iA in 0..<n {
            for iBrev in 0..<m {
                if (iA - iBrev) == (shift - (m - 1)) {
                    out.append((iA, iBrev))
                }
            }
        }
        return out
    }

    func isHighlightedInPairsA(_ indexA: Int) -> Bool {
        highlightedPairs.contains { $0.0 == indexA }
    }

    func isHighlightedInPairsB(_ indexBOriginal: Int) -> Bool {
        let m = b.count
        return highlightedPairs.contains { (_, iBrev) in
            let original = (m - 1 - iBrev)
            return original == indexBOriginal
        }
    }

    func step(_ delta: Int) {
        if delta > 0 {
            stepForward()
        } else if delta < 0 {
            stepBackward()
        }
    }

    private func stepForward() {
        if stage == .original {
            withAnimation(.easeInOut(duration: 0.6)) {
                bRotationDeg = 180
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.none) {
                    self.bIsReversed = true
                    self.bRotationDeg = 0
                }

                withAnimation(.easeInOut(duration: 0.45)) {
                    self.stage = .shiftReady
                }
            }
            return
        }

        let newShift = max(-1, min(convResult.count - 1, shift + 1))
        withAnimation(.easeInOut(duration: 0.35)) {
            shift = newShift
            highlightedPairs =
                (newShift >= 0) ? alignedPairs(shift: shift) : []
        }

        if stage == .shiftReady && shift >= convResult.count - 1 {
            hasFinished = true
        }
    }

    private func stepBackward() {
        if stage == .shiftReady, shift > -1 {
            let newShift = max(-1, shift - 1)
            withAnimation(.easeInOut(duration: 0.35)) {
                shift = newShift
                highlightedPairs =
                    (newShift >= 0) ? alignedPairs(shift: shift) : []
            }
            return
        }

        if stage == .shiftReady, shift == -1 {
            withAnimation(.easeInOut(duration: 0.6)) {
                bRotationDeg = 180
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.none) {
                    self.bIsReversed = false
                    self.bRotationDeg = 0
                    self.stage = .original
                    self.highlightedPairs = []
                }
            }
        }
    }

    func resetAll() {
        withAnimation(.easeInOut(duration: 0.3)) {
            stage = .original
            shift = -1
            highlightedPairs = []
            bIsReversed = false
            bRotationDeg = 0
        }
    }
}
