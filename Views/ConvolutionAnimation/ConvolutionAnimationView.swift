//
//  ConvolutionAnimationView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 11/02/26.
//

import SwiftUI

struct ConvolutionAnimationView: View {
    @ObservedObject var vm: ConvolutionAnimationViewModel

    var body: some View {
        VStack(spacing: 18) {
            header

            blocksSection

            marchingSection

            Spacer()

            controls
        }
        .padding()
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("(3, 4, 5) * (8, 9, 10)")
                    .font(.title3)
                    .monospaced()
            }

            HStack(spacing: 8) {
                Text("= ")
                resultTupleView
            }
            .font(.headline)
        }
    }

    private var resultTupleView: some View {
        HStack(spacing: 0) {
            Text("(")

            ForEach(vm.convResult.indices, id: \.self) { i in
                Group {
                    if i <= vm.shift {
                        Text("\(vm.convResult[i])")
                            .transition(
                                .asymmetric(
                                    insertion: .opacity.combined(with: .scale),
                                    removal: .opacity
                                )
                            )
                    } else {
                        Text(" _ ")
                            .opacity(0.5)
                    }
                }
                .foregroundStyle(.yellow)
                .monospaced()

                if i != vm.convResult.count - 1 {
                    Text(", ")
                }
            }

            Text(")")
        }
        .animation(.easeIn(duration: 0.25), value: vm.shift)
    }

    private var blocksSection: some View {
        VStack(spacing: 12) {
            Group {
                if vm.stage == .original {
                    HStack(alignment: .top, spacing: 40) {
                        vectorRow(
                            values: vm.a,
                            reversed: false,
                            counterRotateTextDeg: 0
                        )
                        vectorRow(
                            values: vm.b,
                            reversed: vm.bIsReversed,
                            counterRotateTextDeg: vm.bRotationDeg
                        )
                        .rotationEffect(.degrees(vm.bRotationDeg))
                    }
                } else {
                    VStack(alignment: .center, spacing: vm.rowSpacingY) {
                        vectorRow(
                            values: vm.a,
                            reversed: false,
                            counterRotateTextDeg: 0
                        )
                        vectorRow(
                            values: vm.b,
                            reversed: vm.bIsReversed,
                            counterRotateTextDeg: vm.bRotationDeg
                        )
                        .rotationEffect(.degrees(vm.bRotationDeg))
                        .offset(x: vm.bOffsetX())
                    }
                }
            }
            .padding(.top, 10)
        }
        .animation(.easeInOut(duration: 0.45), value: vm.stage)
        .animation(.easeInOut(duration: 0.35), value: vm.shift)
    }

    @ViewBuilder
    private func vectorRow(
        values: [Int],
        reversed: Bool,
        counterRotateTextDeg: Double
    ) -> some View {
        let displayed = reversed ? Array(values.reversed()) : values
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(Array(displayed.enumerated()), id: \.offset) {
                    idx,
                    val in
                    let index = reversed ? (values.count - 1 - idx) : idx
                    blockCell(
                        value: val,
                        highlighted: vm.isHighlightedInPairsA(index)
                            || vm.isHighlightedInPairsB(index),
                        counterRotateTextDeg: counterRotateTextDeg
                    )
                }
            }
        }
    }

    private func blockCell(
        value: Int,
        highlighted: Bool,
        counterRotateTextDeg: Double
    ) -> some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        highlighted ? Color.yellow : Color.gray.opacity(0.6),
                        lineWidth: highlighted ? 3 : 2
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.25))
                    )
                    .frame(width: 54, height: 54)

                Text("\(value)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .rotationEffect(.degrees(-counterRotateTextDeg))
            }
        }
    }

    private var marchingSection: some View {
        VStack(spacing: 10) {

            if vm.shift >= 0 {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text("c_\(vm.shift) =")
                            .foregroundStyle(.yellow)
                            .font(.headline)

                        Text(vm.expressionForCurrentShift())
                            .monospaced()
                    }

                    HStack(spacing: 6) {
                        Text("= ")
                        Text("\(vm.convResult[vm.shift])")
                            .foregroundStyle(.yellow)
                            .font(.headline)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12).fill(
                        Color.black.opacity(0.06)
                    )
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: vm.shift)
    }

    private var controls: some View {
        VStack(spacing: 10) {

            HStack(spacing: 10) {
                Button("Prev step") { vm.step(-1) }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.stage == .original)

                Button("Next step") { vm.step(+1) }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        vm.stage == .shiftReady
                            && vm.shift >= vm.convResult.count - 1
                    )

                Button("Reset") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        vm.resetAll()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(vm.shift < 0)
            }
        }
    }
}

#Preview {
    ConvolutionAnimationView(vm: ConvolutionAnimationViewModel())
}
