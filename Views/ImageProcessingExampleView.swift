//
//  ImageProcessingExampleView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 13/02/26.
//

import SwiftUI

struct ImageProcessingExampleView: View {
    @EnvironmentObject private var router: NavRouter
    @StateObject private var vm = ConvolutionViewModel()

    private let box3: [Float] = Array(repeating: 1.0 / 9.0, count: 9)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.background)
                    .ignoresSafeArea()

                VStack {
                    Text("Aplications")
                        .font(.system(size: 68))
                        .bold()
                        .foregroundStyle(.cyan)
                        .padding(.bottom, geo.size.height * 0.01)

                    Text(
                        "This is the whole process of a discrete convolution, and it has a lot of applications in areas such as image processing. Instead of working with lists, we work with two 2D matrices: The image itself (a grid of pixels) and a small matrix called a **kernel**."
                    )
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

                    Spacer()

                    VStack {

                        VStack {
                            HStack {
                                Image("moon")
                                    .resizable()
                                    .interpolation(.none)
                                    .scaledToFit()
                                    .frame(maxHeight: geo.size.height * 0.15)
                                    .grayscale(1.0)

                                Text("*")
                                    .font(.system(size: 68))
                                    .foregroundStyle(.white)

                                VStack(spacing: 0) {
                                    vectorRow()
                                    vectorRow()
                                    vectorRow()
                                }
                            }

                            Text("Result:")
                                .font(.system(size: 20))
                                .foregroundStyle(.secondary)

                            Group {
                                if let out = vm.outputImage {
                                    out
                                        .resizable()
                                        .interpolation(.none)
                                        .scaledToFit()
                                        .overlay(resultKernelOverlay)
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
                            .frame(maxHeight: geo.size.height * 0.15)
                            .contentShape(Rectangle())

                            HStack {
                                Button {
                                    vm.primaryAction()
                                } label: {
                                    Image(systemName: vm.isRunning ? "pause.fill" : "play.fill")
                                        .font(.customBody)
                                        .padding(10)
                                }
                                .clipShape(.circle)
                                .buttonStyle(.borderedProminent)
                           }
                        }
                        .padding(.bottom, 60)

                        Text(
                            "In this example, imagine the black pixels from the image as 0 and the white pixels as 1. As the **kernel** (the little yellow square) slides across the image, it \"looks\" at a small neighborhood, multiplies each pixel by the kernel values, adds everything up, and writes the result back to the center pixel. The resulting picture is a blurred version of the original."
                        )
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                    }
                    .padding(30)
                    .background{
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
                            router.push(.applicationCNN)
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
            vm.useColor = false
            vm.pixelsPerTick = 25
            vm.setCustomKernel(size: 3, kernel: box3)
            vm.setup(assetName: "moon")
            vm.start()
        }
    }

    @ViewBuilder
    private func vectorRow() -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { _ in
                    blockCell(numerator: "1", denominator: "9")
                }
            }
        }
    }

    private func blockCell(numerator: String, denominator: String) -> some View
    {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.gray.opacity(0.6), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.25))
                    )
                    .frame(width: 50, height: 50)

                VStack(spacing: 2) {
                    Text(numerator)
                        .font(
                            .system(
                                size: 13,
                                weight: .semibold,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(.white)

                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 18, height: 1)

                    Text(denominator)
                        .font(
                            .system(
                                size: 13,
                                weight: .semibold,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(.white)
                }
            }
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

            let kernelSize = 3
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
}

#Preview {
    ImageProcessingExampleView()
}
