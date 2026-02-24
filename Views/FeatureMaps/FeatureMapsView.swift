//
//  FeatureMapsView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 19/02/26.
//


/// This view was used to further explain the usage of the convolution in CNNs, but it was scrapped, as it tangenciates the app's main subject.

import SwiftUI

struct FeatureMapsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = FeatureMapsViewModel()

    @State private var isPressed: Bool = false
    @State private var selectedIndex: Int? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    Text("Aplications")
                        .font(.system(size: 68))
                        .foregroundStyle(.cyan)
                        .padding(.bottom, 20)

                    Text(
                        "A CNN applies many convollutions in parallel. Each kernel highlights a different pattern, creating multiple **feature maps** from the same input."
                    )
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

                    Spacer()

                    let cellW = geo.size.width * 0.7
                    VStack(spacing: 14) {
                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible(), spacing: 14),
                                count: 4
                            ),
                            spacing: 14
                        ) {
                            originalCell
                                .frame(height: cellW * 0.22)

                            ForEach(0..<vm.outputs.count, id: \.self) { i in
                                mapCell(index: i)
                                    .frame(height: cellW * 0.22)
                            }
                        }
                        .frame(width: cellW)

                        if let idx = selectedIndex {
                            kernelInspector(for: idx)
                                .frame(width: cellW)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }

                    Spacer()

                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Text("Back")
                                .font(.system(size: 24))
                                .padding(10)
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button {
                            isPressed = true
                        } label: {
                            Text("Next")
                                .font(.system(size: 24))
                                .padding(10)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
                .navigationDestination(isPresented: $isPressed) {
                    
                }
                .navigationBarBackButtonHidden()
            }
        }
        .task {
            vm.setup(assetName: "seven")
            vm.start()
        }
        .onDisappear { vm.stop() }
        .animation(.linear(duration: 0.2), value: selectedIndex)
    }

    private var originalCell: some View {
        ZStack(alignment: .bottomLeading) {
            Image("seven")
                .resizable()
                .interpolation(.none)
                .scaledToFit()

            Text("Original")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.06))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func mapCell(index: Int) -> some View {
        let kernel = vm.kernels[index]
        let isSelected = selectedIndex == index

        return ZStack(alignment: .bottomLeading) {
            Group {
                if let img = vm.outputs[index] {
                    img
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .overlay(kernelOverlay(kernelSize: kernel.size))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.08))
                        .overlay(
                            Text("Computing...").foregroundStyle(.secondary)
                        )
                }
            }

            Text(kernel.name)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12).fill(
                .white.opacity(isSelected ? 0.12 : 0.06)
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .onTapGesture {
            selectedIndex = (selectedIndex == index) ? nil : index
        }
    }

    private func kernelOverlay(kernelSize: Int) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            let imgW = max(1, vm.engine.imageWidth)
            let imgH = max(1, vm.engine.imageHeight)

            let x = w * CGFloat(vm.engine.cursorX) / CGFloat(imgW)
            let y = h * CGFloat(vm.engine.cursorY) / CGFloat(imgH)

            let kw = w * CGFloat(kernelSize) / CGFloat(imgW)
            let kh = h * CGFloat(kernelSize) / CGFloat(imgH)

            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(.yellow, lineWidth: 2)
                .frame(width: kw, height: kh)
                .position(x: x + kw / 2, y: y + kh / 2)
                .animation(.linear(duration: 1.0 / 30.0), value: vm.engine.cursorX)
                .animation(.linear(duration: 1.0 / 30.0), value: vm.engine.cursorY)
        }
    }

    private func kernelInspector(for index: Int) -> some View {
        let k = vm.kernels[index]
        return VStack(alignment: .leading, spacing: 10) {
            Text("Selected kernel: \(k.name)")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)

            kernelGrid(k)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.06))
        )
    }

    private func kernelGrid(_ k: KernelSpec) -> some View {
        let s = k.size
        return VStack(spacing: 6) {
            ForEach(0..<s, id: \.self) { r in
                HStack(spacing: 6) {
                    ForEach(0..<s, id: \.self) { c in
                        let v = k.weights[r * s + c]
                        Text(formatKernelValue(v))
                            .font(
                                .system(
                                    size: 14,
                                    weight: .semibold,
                                    design: .monospaced
                                )
                            )
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 8).fill(
                                    .white.opacity(0.08)
                                )
                            )
                    }
                }
            }
        }
    }

    private func formatKernelValue(_ v: Float) -> String {
        // enxuto e legível
        if abs(v) >= 1 {
            return String(format: "%.0f", v)
        } else {
            return String(format: "%.2f", v)
        }
    }
}
