//
//  ConvolutionAnimationView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 11/02/26.
//

import SwiftUI

struct ConvolutionAnimationView: View {
    @ObservedObject var vm: ConvolutionAnimationViewModel
    @Namespace private var ns
    private let isIpad: Bool = UIDevice.current.userInterfaceIdiom == .pad

    var body: some View {
        HStack(spacing: 16) {

            Button {
                vm.step(-1)
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.customBody)
                    .padding(10)
            }
            .clipShape(.circle)
            .buttonStyle(.borderedProminent)
            .disabled(vm.stage == .original)

            VStack {
                header

                blocksSection
                    .frame(minHeight: 150, alignment: .top)

                marchingSection
                    .frame(minHeight: 70, alignment: .top)
            }
            .frame(minWidth: 400)

            Button {
                vm.step(+1)
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.customBody)
                    .padding(10)

            }
            .clipShape(.circle)
            .buttonStyle(.borderedProminent)
            .disabled(
                vm.stage == .shiftReady
                    && vm.shift >= vm.convResult.count - 1
            )
        }
        .padding()
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("(3, 4, 5) * (8, 9, 10)")
                    .font(.customBody)
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
                .font(.customBody)

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
                            .font(.customBody)
                            .opacity(0.5)
                    }
                }
                .font(.customBody)
                .foregroundStyle(.yellow)
                .monospaced()

                if i != vm.convResult.count - 1 {
                    Text(", ")
                        .font(.customBody)
                }
            }

            Text(")")
                .font(.customBody)
        }
        .animation(.easeIn(duration: 0.25), value: vm.shift)
    }

    private var blocksSection: some View {
        VStack(spacing: 12) {
            Group {
                if vm.stage == .original || vm.stage == .startAnimation {
                    HStack(alignment: .top, spacing: 40) {
                        vectorRow(
                            values: vm.a,
                            reversed: false,
                            counterRotateTextDeg: 0
                        )
                        .matchedGeometryEffect(id: "a-row", in: ns)

                        vectorRow(
                            values: vm.b,
                            reversed: vm.bIsReversed,
                            counterRotateTextDeg: vm.bRotationDeg
                        )
                        .rotationEffect(.degrees(vm.bRotationDeg))
                        .matchedGeometryEffect(id: "b-row", in: ns)
                    }
                } else {
                    VStack(alignment: .center, spacing: vm.rowSpacingY) {
                        vectorRow(
                            values: vm.a,
                            reversed: false,
                            counterRotateTextDeg: 0
                        )
                        .matchedGeometryEffect(id: "a-row", in: ns)

                        vectorRow(
                            values: vm.b,
                            reversed: vm.bIsReversed,
                            counterRotateTextDeg: vm.bRotationDeg
                        )
                        .rotationEffect(.degrees(vm.bRotationDeg))
                        .offset(x: vm.bOffsetX())
                        .matchedGeometryEffect(id: "b-row", in: ns)
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
                        highlighted
                            ? Color.yellow : Color.gray.opacity(0.6),
                        lineWidth: highlighted ? 3 : 2
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.25))
                    )
                    .frame(width: isIpad ? 54 : 40, height: isIpad ? 54 : 40)

                Text("\(value)")
                    .font(.customBodySmall)
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
                .disabled(vm.stage == .original)
            }
        }
    }
}

#Preview {
    ConvolutionAnimationView(vm: ConvolutionAnimationViewModel())
}
