//
//  ConvolutionView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 04/02/26.
//

import SwiftUI

struct ConvolutionView: View {
    @EnvironmentObject private var router: NavRouter
    @StateObject private var vm = ConvolutionViewModel()

    private enum Source {
        case asset(String)
        case photo(Data)
    }

    private let source: Source

    init(assetName: String) {
        self.source = .asset(assetName)
    }

    init(imageData: Data) {
        self.source = .photo(imageData)
    }

    var body: some View {
        ZStack {
            Color("backgroundColor")
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
                                .accessibilityElement(children: .ignore)
                                .accessibilityAddTraits(.isImage)
                                .accessibilityLabel("Original image")
                                .accessibilityHint(
                                    "Input image used for the convolution."
                                )
                        } else {
                            Text("Image not found")
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
                                .accessibilityElement(children: .ignore)
                                .accessibilityAddTraits(.isImage)
                                .accessibilityLabel("Result image")
                                .accessibilityValue(
                                    "Kernel: \(vm.selectedPreset.rawValue). \(vm.selectedPreset.isBlur ? "Intensity: \(vm.blurIntensity.rawValue)." : "")"
                                )
                                .accessibilityHint(
                                    "Output after applying the selected kernel."
                                )
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
                                ForEach(KernelPreset.allCases.reversed()) {
                                    preset in
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
                            .accessibilityLabel("Kernel")
                            .accessibilityValue(vm.selectedPreset.rawValue)
                            .accessibilityHint("Double tap to choose a kernel.")
                        }

                        Spacer()

                        VStack(spacing: 18) {
                            Text("Intensity")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(.white)

                            Menu {
                                ForEach(BlurIntensity.allCases.reversed()) {
                                    intensity in
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
                            .accessibilityLabel("Intensity")
                            .accessibilityValue(vm.blurIntensity.rawValue)
                            .accessibilityHint(
                                vm.selectedPreset.isBlur
                                    ? "Double tap to choose blur intensity."
                                    : "Available only for blur kernels."
                            )

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
                        .accessibilityLabel("Step once")
                        .accessibilityHint("Advances the scan by one step.")

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
                        .accessibilityLabel(vm.isRunning ? "Pause" : "Play")
                        .accessibilityValue(vm.isRunning ? "Running" : "Paused")
                        .accessibilityHint(
                            vm.isRunning
                                ? "Pauses the convolution scan."
                                : "Starts the convolution scan."
                        )

                        Button {
                            vm.reset()
                        } label: {
                            Text("Reset")
                                .font(.system(size: 26))
                                .padding(10)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Reset")
                        .accessibilityHint(
                            "Resets the scan position and clears the result."
                        )
                    }

                    HStack(spacing: 24) {
                        Text("Speed")
                            .foregroundStyle(.white)
                            .font(.customBodySmall)
                            .accessibilityHidden(true)

                        LogSlider(
                            value: $vm.pixelsPerTick,
                            minValue: 1,
                            maxValue: 1000,
                            step: 1
                        )

                        Text("\(Int(vm.pixelsPerTick)) px/step")
                            .font(.customBodySmall)
                            .foregroundStyle(.white)
                            .frame(width: 140, alignment: .trailing)
                            .accessibilityHidden(true)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Speed")
                    .accessibilityValue("\(Int(vm.pixelsPerTick)) pixels per step")
                    .accessibilityHint("Adjusts how fast the kernel scans the image.")
                }

                HStack(spacing: 16) {
                    Image(systemName: "info.circle")
                        .font(.customBody)
                        .foregroundStyle(.cyan)
                        .accessibilityHidden(true)

                    Text(vm.selectedPreset.description)
                        .foregroundStyle(.white)
                        .font(.customBodySmall)
                        .accessibilityHidden(true)
                }
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.cyan, lineWidth: 2)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Kernel description")
                .accessibilityValue(vm.selectedPreset.description)

                Spacer()

                HStack {
                    Button {
                        router.pop()
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
            .task {
                switch source {
                case .asset(let name):
                    vm.setup(assetName: name)
                case .photo(let data):
                    vm.setup(imageData: data)
                }
            }
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
        .environmentObject(NavRouter())
}
