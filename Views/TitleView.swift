//
//  TitleView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 25/02/26.
//

import SwiftUI

struct TitleView: View {
    @EnvironmentObject private var router: NavRouter
    @StateObject private var vm = ConvolutionViewModel()

    private enum FocusEnum: Hashable { case start, playground }
    @AccessibilityFocusState private var focus: FocusEnum?

    private let kernelCycle: [KernelSpec] = [
        .init(
            name: "Identity",
            size: 3,
            weights: [
                0, 0, 0,
                0, 1, 0,
                0, 0, 0,
            ]
        ),
        .init(
            name: "Edge Detect",
            size: 3,
            weights: KernelPreset.edgeDetect.makeKernel(size: 3)
        ),
        .init(
            name: "Sobel X",
            size: 3,
            weights: KernelPreset.sobelX.makeKernel(size: 3)
        ),
        .init(
            name: "Gaussian Blur",
            size: 13,
            weights: KernelPreset.gaussianBlur.makeKernel(size: 13)
        ),
    ]

    @State private var kernelIndex = 0
    @State private var cycleTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color("backgroundColor")
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    Group {
                        if let out = vm.outputImage {
                            out
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.8)
                                .overlay(
                                    resultKernelOverlay.accessibilityHidden(
                                        true
                                    )
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.08))
                                .overlay(
                                    Text("Rendering...")
                                        .foregroundStyle(.secondary)
                                        .font(
                                            .system(
                                                size: 18,
                                                design: .monospaced
                                            )
                                        )
                                )
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Convolution app title")
                    .accessibilityValue(
                        "Kernel: \(kernelCycle[kernelIndex].name)"
                    )
                    .accessibilityHint("The kernel changes automatically")

                    Spacer()

                    Button {
                        router.push(.intro)
                    } label: {
                        Text("Start")
                            .foregroundStyle(.white)
                            .font(.system(size: 30, weight: .bold))
                            .padding(10)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 40)
                    .accessibilityLabel("Start")
                    .accessibilityHint("Start the lesson on convolution")
                    .accessibilityFocused($focus, equals: .start)

                    Button {
                        router.push(.playgroundMenu)
                    } label: {
                        Text("Playground")
                            .foregroundStyle(.white)
                            .font(.system(size: 30, weight: .bold))
                            .padding(10)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Playground")
                    .accessibilityHint(
                        "Opens the playground to test kernels on images."
                    )
                    .accessibilityFocused($focus, equals: .playground)

                    Spacer()
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
            }
        }
        .task {
            vm.useColor = true
            vm.pixelsPerTick = 60
            vm.setup(assetName: "Title")
            applyKernel(kernelCycle[kernelIndex])
            vm.start()

            startKernelCycleLoop(everySeconds: 8)
        }
        .onDisappear {
            cycleTask?.cancel()
            cycleTask = nil
            vm.stop()
        }
    }

    private var resultKernelOverlay: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            let imgW = max(1, vm.imageWidth)
            let imgH = max(1, vm.imageHeight)

            let x = w * CGFloat(vm.cursorX) / CGFloat(imgW)
            let y = h * CGFloat(vm.cursorY) / CGFloat(imgH)

            let kernelSize = 15
            let kw = w * CGFloat(kernelSize) / CGFloat(imgW)
            let kh = h * CGFloat(kernelSize) / CGFloat(imgH)

            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(.yellow, lineWidth: 2)
                .frame(width: kw, height: kh)
                .position(x: x + kw / 2, y: y + kh / 2)
                .animation(.linear(duration: 1.0 / 30.0), value: vm.cursorX)
                .animation(.linear(duration: 1.0 / 30.0), value: vm.cursorY)
        }
    }

    private func startKernelCycleLoop(everySeconds seconds: Double) {
        cycleTask?.cancel()
        cycleTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(
                    nanoseconds: UInt64(seconds * 1_000_000_000)
                )

                kernelIndex = (kernelIndex + 1) % kernelCycle.count
                let next = kernelCycle[kernelIndex]

                vm.stop()
                applyKernel(next)
                vm.reset()
                vm.start()
            }
        }
    }

    @MainActor
    private func applyKernel(_ item: KernelSpec) {
        vm.setCustomKernel(size: item.size, kernel: item.weights)
    }
}

#Preview {
    TitleView()
        .environmentObject(NavRouter())
}
