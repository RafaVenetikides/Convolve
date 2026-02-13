//
//  ImageProcessingExampleView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 13/02/26.
//

import SwiftUI

struct ImageProcessingExampleView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPressed = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack {
                    Text("Aplications")
                        .font(.system(size: 68))
                        .foregroundStyle(.cyan)
                        .padding(.bottom, 20)

                    Text(
                        "This is the whole process of a discrete convolution, and it has a lot of applications in areas such as image processing. Which, instead of lists, we use 2 matrices, using the rgb values of the pixels as operators."
                    )
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

                    Spacer()

                    VStack {
                        HStack {
                            Image("moon")
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(maxHeight: geo.size.height * 0.2)

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
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)

                        Image("moon_blur")
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(maxHeight: geo.size.height * 0.2)
                    }

                    Spacer()

                    Text(
                        "In this case, imagine the black pixels from the image as 0 and the white pixels as 1, we can convolute them with this 3x3 matrix and the resulting picture is a blurred version of the original."
                    )
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

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
                    ConvolutionDemoView()
                }
                .navigationBarBackButtonHidden()
            }
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
                    .frame(width: 60, height: 60)

                VStack(spacing: 2) {
                    Text(numerator)
                        .font(
                            .system(
                                size: 16,
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
                                size: 16,
                                weight: .semibold,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

#Preview {
    ImageProcessingExampleView()
}
