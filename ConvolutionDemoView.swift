//
//  ConvolutionDemoView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 04/02/26.
//

import SwiftUI

struct ConvolutionDemoView: View{
    @StateObject private var vm = ConvolutionViewModel()

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                VStack( alignment: .leading, spacing: 8) {
                    Text("Original")
                        .font(.headline)

                    if let img = vm.originalUIImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .overlay(kernelOverlay)
                            .clipped()
                    } else {
                        Text("Asset not found")
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Exit (convolution)")
                        .font(.headline)

                    if let out = vm.outputImage {
                        out
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .overlay(kernelOverlay)
                            .clipped()
                    }
                }
            }

            controls
                .tint(.blue)

            Text("Cursor: (\(vm.cursorX), \(vm.cursorY))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .task { vm.setup() }
    }

    private var kernelOverlay: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            let x = w * CGFloat(vm.cursorX) / CGFloat(max(1, vm.imageWidth))
            let y = h * CGFloat(vm.cursorY) / CGFloat(max(1, vm.imageHeight))

            let kw = w * CGFloat(vm.kernelSize) / CGFloat(max(1, vm.imageWidth))
            let kh = h * CGFloat(vm.kernelSize) / CGFloat(max(1, vm.imageHeight))

            Rectangle()
                .strokeBorder(.yellow, lineWidth: 2)
                .frame(width: kw, height: kh)
                .position(x: x + kw/2, y: y + kh/2)
                .animation(.linear(duration: 1.0/60.0), value: vm.cursorX)
                .animation(.linear(duration: 1.0/60.0), value: vm.cursorY)
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(vm.isRunning ? "Pause" : "Play") { vm.togglePlay() }
                    .buttonStyle(.borderedProminent)

                Button("Step") { vm.stepOnce() }
                    .buttonStyle(.bordered)

                Button("Reset") { vm.reset() }
                    .buttonStyle(.bordered)
            }

            HStack {
                Text("Speed")
                Slider(value: $vm.pixelsPerTick, in: 1...10000, step: 1)
                Text("\(Int(vm.pixelsPerTick)) px/tick")
                    .monospacedDigit()
                    .frame(width: 120, alignment: .trailing)
            }
        }
    }
}
