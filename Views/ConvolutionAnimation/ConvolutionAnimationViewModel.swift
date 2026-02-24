//
//  ConvolutionAnimationViewModel.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 12/02/26.
//

import SwiftUI

@MainActor
final class ConvolutionAnimationViewModel: ObservableObject {
    enum Stage {
        case original
        case startAnimation
        case shiftReady
    }

    enum InstructionStep: Equatable {
        case intro
        case flip
        case multiply
        case shift
    }

    let a: [Int]
    let b: [Int]

    var convResult: [Int] { a.convolve(with: b) }

    @Published private(set) var shift: Int = -1
    var highlightedPairs: [(Int, Int)] {
        shift >= 0 ? alignedPairs(shift: shift) : []
    }

    @Published private(set) var stage: Stage = .original
    @Published private(set) var instructionStep: InstructionStep = .intro
    @Published var bIsReversed: Bool = false
    @Published var bRotationDeg: Double = 0

    let cellPitch: CGFloat
    let rowSpacingY: CGFloat = 18

    @Published private(set) var isAnimating = false
    @Published private(set) var hasFinished = false

    init(a: [Int] = [3, 4, 5], b: [Int] = [8, 9, 10]) {
        self.a = a
        self.b = b

        self.cellPitch = UIDevice.current.userInterfaceIdiom == .pad ? 54 : 40
    }

    func bOffsetX() -> CGFloat {
        guard shift >= 0 else { return 0 }
        let sizeListB = b.count
        let deltaCells = shift - (sizeListB - 1)
        return CGFloat(deltaCells) * cellPitch
    }

    func expressionForCurrentShift() -> String {
        let pairs = alignedPairs(shift: shift)
        return pairs.map { (indexListA, indexListB) in
            let valueA = a[indexListA]
            let valueB = b.reversed()[indexListB]
            return "\(valueA)·\(valueB)"
        }.joined(separator: " + ")
    }

    private func alignedPairs(shift: Int) -> [(Int, Int)] {
        let sizeListA = a.count
        let sizeListB = b.count
        var out: [(Int, Int)] = []
        for indexListA in 0..<sizeListA {
            for indexListB in 0..<sizeListB {
                if (indexListA - indexListB) == (shift - (sizeListB - 1)) {
                    out.append((indexListA, indexListB))
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
        return highlightedPairs.contains { (_, indexListB) in
            let original = (m - 1 - indexListB)
            return original == indexBOriginal
        }
    }

    func step(_ delta: Int) {
        guard !isAnimating else { return }
        if delta > 0 {
            stepForward()
        } else if delta < 0 {
            stepBackward()
        }
    }

    private func stepForward() {
        switch stage {
        case .original:

            withAnimation(.easeIn(duration: 0.25)) {
                instructionStep = .flip
            }

            withAnimation(.easeInOut(duration: 0.45)) {
                self.stage = .startAnimation
            }

        case .startAnimation:
            isAnimating = true

            withAnimation(.easeInOut(duration: 0.6)) {
                bRotationDeg = 180
            }

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))

                withAnimation(.none) {
                    bIsReversed = true
                    bRotationDeg = 0
                }

                withAnimation(.easeIn(duration: 0.25)) {
                    instructionStep = .multiply
                }

                withAnimation(.easeInOut(duration: 0.45)) {
                    stage = .shiftReady
                    shift = -1
                }

                isAnimating = false
            }
            return

        case .shiftReady:

            let newShift = max(-1, min(convResult.count - 1, shift + 1))
            withAnimation(.easeInOut(duration: 0.35)) {
                shift = newShift
            }

            if newShift >= 0, instructionStep != .shift {
                withAnimation(.easeIn(duration: 0.25)) {
                    instructionStep = .shift
                }
            }

            if shift >= convResult.count - 1 {
                hasFinished = true
            }
        }
    }

    private func stepBackward() {
        if stage == .shiftReady, shift > -1 {
            let newShift = max(-1, shift - 1)
            withAnimation(.easeInOut(duration: 0.35)) {
                shift = newShift
            }

            if newShift == -1, instructionStep != .multiply {
                withAnimation(.easeIn(duration: 0.25)) {
                    instructionStep = .multiply
                }
            }

            return
        }

        if stage == .shiftReady, shift == -1 {
            isAnimating = true

            withAnimation(.easeInOut(duration: 0.6)) {
                bRotationDeg = 180
            }

            Task{ @MainActor in
                try? await Task.sleep(for: .milliseconds(600))

                withAnimation(.none) {
                    bIsReversed = false
                    bRotationDeg = 0
                    stage = .startAnimation
                }

                withAnimation(.easeIn(duration: 0.25)) {
                    instructionStep = .flip
                }

                isAnimating = false
            }
        }

        if stage == .startAnimation {
            withAnimation(.easeInOut(duration: 0.3)) {
                stage = .original
                instructionStep = .intro
            }
        }
    }

    func resetAll() {
        isAnimating = false

        withAnimation(.easeInOut(duration: 0.3)) {
            stage = .original
            shift = -1
            bIsReversed = false
            bRotationDeg = 0
            instructionStep = .intro
        }
    }
}
