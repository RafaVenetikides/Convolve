//
//  NeuralNetworkExampleView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 13/02/26.
//

import SwiftUI

struct NeuralNetworkExampleView: View {
    @EnvironmentObject private var router: NavRouter
    @StateObject private var vm = NeuralConvolutionsViewModel()

    @State private var loopTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color("backgroundColor")
                    .ignoresSafeArea()

                VStack {
                    Text("Aplications")
                        .font(.customTitle)
                        .bold()
                        .foregroundStyle(.cyan)
                        .padding(.bottom, 20)

                    Text(
                        "Convolutions are also a big deal in Artificial Intelligence, especially in **Convolutional Neural Networks** (CNNs). This type of neural network uses convolution to extract information from all kinds of data, like images, text or even audio, to interpret it and make classifications."
                    )
                    .font(.customBody)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

                    Spacer()

                    VStack {
                        Grid(horizontalSpacing: 60, verticalSpacing: 60) {
                            GridRow {
                                Image("seven")
                                    .resizable()
                                    .interpolation(.none)
                                    .scaledToFit()

                                outputCell(vm.outEdge, label: "Edge Detect")
                            }

                            GridRow {
                                outputCell(vm.outSobelX, label: "Sobel X")
                                outputCell(vm.outSobelY, label: "Sobel Y")
                            }
                        }
                        .frame(width: geo.size.width * 0.55)
                        .padding(.bottom, 40)

                        Text(
                            "With each new convolution layer, the network learns to spot patterns, first simple ones like edges, then more complex shapes, until it can recognize things like a handwritten digit. The images above show examples of these extracted patterns."
                        )
                        .font(.customBodySmall)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                    }
                    .padding(30)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white)
                    }
                    .padding(.horizontal, 60)

                    Spacer()

                    HStack {
                        Button {
                            router.pop()
                        } label: {
                            Text("Back")
                                .font(.system(size: 24))
                                .padding(10)
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button {
                            router.push(.playgroundIntro)
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
                .navigationBarBackButtonHidden()
            }
        }
        .task {
            vm.setup(assetName: "seven")
            vm.start()

            startLoop(pauseSeconds: 5)
        }
        .onDisappear {
            loopTask?.cancel()
            loopTask = nil
            vm.stop()
        }
    }

    private func outputCell(_ img: Image?, label: String) -> some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let img {
                    img
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .overlay(kernelOverlay(kernelSize: vm.kernelSize))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.08))
                        .overlay(
                            Text("Computing...").foregroundStyle(.secondary)
                        )
                }
            }

            Text(label)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(8)
                .offset(y: 10)
        }
    }

    private func kernelOverlay(kernelSize: Int) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            let imgW = max(1, vm.imageWidth)
            let imgH = max(1, vm.imageHeight)

            let x = w * CGFloat(vm.cursorX) / CGFloat(imgW)
            let y = h * CGFloat(vm.cursorY) / CGFloat(imgH)

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

    @MainActor
    private func startLoop(pauseSeconds: Double) {
        loopTask?.cancel()

        loopTask = Task { @MainActor in
            while !Task.isCancelled {

                while !vm.isFinished && !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 50_000_000)
                }
                if Task.isCancelled { break }

                if pauseSeconds > 0 {
                    let ns = UInt64(pauseSeconds * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: ns)
                }

                vm.reset()

                try? await Task.sleep(nanoseconds: 80_000_000)

                vm.start()
            }
        }
    }
}

#Preview {
    NeuralNetworkExampleView()
}
