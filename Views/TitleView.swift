//
//  TitleView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 25/02/26.
//

import SwiftUI

struct TitleView: View {
    @EnvironmentObject private var router: NavRouter
    @State private var isSpinning = false
    @StateObject private var vm = ConvolutionViewModel()

    private let customKernel: [Float] = {
        let size = 3
        var kernel = Array(repeating: 0.0 as Float, count: size * size)
        let center = size / 2
        kernel[center * size + center] = 1.0
        return kernel
    }()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.background)
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

                    Spacer()

                    Button{
                        router.push(.intro)
                    } label: {
                        Text("Start")
                            .foregroundStyle(.white)
                            .font(.system(size: 30, weight: .bold))
                            .padding(10)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 40)

                    Button{
                        router.push(.playgroundMenu)
                    } label: {
                        Text("Playground")
                            .foregroundStyle(.white)
                            .font(.system(size: 30, weight: .bold))
                            .padding(10)
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
            }
        }
        .task {
            vm.useColor = true
            vm.pixelsPerTick = 40
            vm.setCustomKernel(size: 3, kernel: customKernel)
            vm.setup(assetName: "Title")
            vm.start()
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
}

#Preview {
    TitleView()
        .environmentObject(NavRouter())
}
