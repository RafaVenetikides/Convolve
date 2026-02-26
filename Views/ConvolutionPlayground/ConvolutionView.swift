//
//  ConvolutionView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 04/02/26.
//

import SwiftUI

struct ConvolutionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = ConvolutionViewModel()
    let assetName: String

    var body: some View {
        ZStack {
            Color(.background)
                .ignoresSafeArea()

            VStack(spacing: 16) {

                Spacer()

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Original")
                            .font(.customBodySmall)
                            .foregroundStyle(.white)

                        if let img = vm.originalUIImage {
                            Image(uiImage: img)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .overlay(kernelOverlay)
                                .clipped()
                        } else {
                            Text("Asset not found")
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Result")
                            .font(.customBodySmall)
                            .foregroundStyle(.white)

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

                VStack(spacing: 12) {
                    HStack {
                        VStack(spacing: 18) {
                            Text("Kernel")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(.white)

                            Menu {
                                ForEach(KernelPreset.allCases) { preset in
                                    Button {
                                        vm.selectedPreset = preset
                                        vm.setPreset(preset)
                                    } label: {
                                            Text(preset.rawValue)
                                                .font(.system(size: 22))
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(vm.selectedPreset.rawValue)
                                        .font(.system(size: 22))

                                    Image(systemName: "chevron.up.chevron.down")
                                }
                            }
                        }

                        Spacer()

                        VStack(spacing: 18) {
                            Text("Intensity")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(.white)

                            Menu {
                                ForEach(BlurIntensity.allCases) { intensity in
                                    Button {
                                        vm.setBlurIntensity(intensity)
                                    } label: {
                                            Text(intensity.rawValue)
                                                .font(.system(size: 22))
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(vm.blurIntensity.rawValue)
                                        .font(.system(size: 22))

                                    Image(systemName: "chevron.up.chevron.down")
                                }
                            }
                            .disabled(!vm.selectedPreset.isBlur)

                        }
                    }
                    .frame(width: 300)
                    .padding(20)
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.white, lineWidth: 2)
                    }
                    HStack(spacing: 24) {

                        Button {
                            vm.stepOnce()
                        } label: {
                            Text("Step")
                                .font(.system(size: 26))
                                .padding(10)
                        }
                            .buttonStyle(.bordered)

                        Button {
                            vm.primaryAction()
                        } label: {
                            Image(
                                systemName: vm.isRunning
                                    ? "pause.fill" : "play.fill"
                            )
                            .padding(10)
                            .font(.customBody)
                            .bold()
                        }
                        .clipShape(.circle)
                        .buttonStyle(.borderedProminent)

                        Button {
                            vm.reset()
                        } label: {
                            Text("Reset")
                                .font(.system(size: 26))
                                .padding(10)
                        }
                            .buttonStyle(.bordered)
                    }

                    HStack(spacing: 24) {
                        Text("Speed")
                            .foregroundStyle(.white)
                            .font(.customBodySmall)

                        LogSlider(
                            value: $vm.pixelsPerTick,
                            minValue: 1,
                            maxValue: 1000,
                            step: 1
                        )

                        Text("\(Int(vm.pixelsPerTick)) px/step")
                            .font(.customBodySmall)
                            .foregroundStyle(.white)
                            .frame(width: 120, alignment: .trailing)
                    }
                }

                HStack(spacing: 16) {
                    Image(systemName: "info.circle")
                        .font(.customBody)
                        .foregroundStyle(.cyan)

                    Text(vm.selectedPreset.description)
                        .foregroundStyle(.white)
                        .font(.customBodySmall)
                }
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.cyan, lineWidth: 2)
                }

                Spacer()

                HStack {
                    Button {
                            dismiss()
                        } label: {
                            Text("Back")
                                .font(.system(size: 24))
                                .padding()
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                }
            }
            .navigationBarBackButtonHidden()
            .padding()
            .task { vm.setup(assetName: assetName) }
            .onChange(
                of: vm.pixelsPerTick,
                { _, newValue in
                    vm.updateSpeed(newValue)
                }
            )
        }
    }

    private var kernelOverlay: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            let x = w * CGFloat(vm.cursorX) / CGFloat(max(1, vm.imageWidth))
            let y = h * CGFloat(vm.cursorY) / CGFloat(max(1, vm.imageHeight))

            let kw = w * CGFloat(vm.kernelSize) / CGFloat(max(1, vm.imageWidth))
            let kh =
                h * CGFloat(vm.kernelSize) / CGFloat(max(1, vm.imageHeight))

            Rectangle()
                .strokeBorder(.yellow, lineWidth: 2)
                .frame(width: kw, height: kh)
                .position(x: x + kw / 2, y: y + kh / 2)
                .animation(.linear(duration: 1.0 / 60.0), value: vm.cursorX)
                .animation(.linear(duration: 1.0 / 60.0), value: vm.cursorY)
        }
    }
}

#Preview {
    ConvolutionView(assetName: "moon")
}
