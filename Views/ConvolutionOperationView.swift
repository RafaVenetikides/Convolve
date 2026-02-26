//
//  ConvolutionOperationView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 12/02/26.
//

import SwiftUI

struct ConvolutionOperationView: View {
    @StateObject private var vm = ConvolutionAnimationViewModel()
    @EnvironmentObject private var router: NavRouter
    private let isIpad: Bool = UIDevice.current.userInterfaceIdiom == .pad

    var stepText: AttributedString {
        let raw: String

        switch vm.instructionStep {
        case .intro:
            raw =
                ""
        case .flip:
            raw = "First we **flip** the second list of numbers"

        case .multiply:
            raw =
                "We **multiply** the first and last operators from the lists, and **add** all the results"
        case .shift:
            raw =
                "Then we **shift** the lists and repeat the second step until it's over"
        }

        return (try? AttributedString(markdown: raw)) ?? AttributedString(raw)
    }

    var stepNumber: Int {
        switch vm.instructionStep {
        case .intro:
            0
        case .flip:
            1
        case .multiply:
            2
        case .shift:
            3
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.background)
                    .ignoresSafeArea()

                VStack {
                    Text("Operation")
                        .font(.customTitle)
                        .bold()
                        .foregroundStyle(.cyan)
                        .padding(.bottom, geo.size.height * 0.01)

                    VStack(alignment: .center) {
                        if vm.instructionStep == .intro {
                            HStack(alignment: .top) {
                                Text(
                                    "We will take a look at a much simpler version of convolution called discrete convolution. For this, I want you to imagine a pair of lists of numbers, in which we will be applying the convolution."
                                )
                                .font(.customBody)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.leading)

                                Spacer()
                            }
                        } else {
                            HStack {
                                Text(
                                    "The operation happens in 3 simple steps."
                                )
                                .font(.customBody)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.leading)
                                .padding(.bottom, geo.size.height * 0.05)

                                Spacer()
                            }

                            Text("Step \(stepNumber)")
                                .font(.customTitleSmall)
                                .foregroundStyle(Color(.subtitleOrange))
                        }

                        if vm.instructionStep != .intro {
                            Text(stepText)
                                .font(.customBody)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.leading)
                                .contentTransition(.opacity)
                                .animation(
                                    .easeIn(duration: 0.25),
                                    value: stepText
                                )
                                .frame(minHeight: geo.size.height * 0.07)
                        }

                        Spacer()
                    }
                    .frame(
                        height: isIpad
                            ? geo.size.height * 0.25 : geo.size.height * 0.2
                    )

                    ConvolutionAnimationView(vm: vm)

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
                            router.push(.applicationImage)
                        } label: {
                            Text("Next")
                                .font(.system(size: 24))
                                .padding(10)
                        }
                        .disabled(!vm.hasFinished)
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
            }
            .navigationBarBackButtonHidden()
        }
    }
}

#Preview {
    ConvolutionOperationView()
}
