//
//  IntroductionView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 10/02/26.
//

import SwiftUI

struct IntroductionView: View {
    @State private var isPressed = false

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    Color(.background)
                        .ignoresSafeArea()

                    VStack {
                        Text("Introduction")
                            .font(.customTitle)
                            .bold()
                            .foregroundStyle(.cyan)
                            .padding(.bottom, geo.size.height * 0.015)

                        Text(
                            "Have you ever wondered how photo-editing software apply many visual effects to images, or how AI can make sense of what’s in a picture?"
                        )
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .font(.customBody)

                        Spacer()

                        Grid(horizontalSpacing: geo.size.width * 0.05, verticalSpacing: geo.size.width * 0.05) {
                            GridRow {
                                Image("cat")
                                    .resizable()
                                    .interpolation(.none)
                                    .scaledToFit()

                                Image("cat_blur")
                                    .resizable()
                                    .interpolation(.none)
                                    .scaledToFit()
                            }

                            GridRow {
                                Image("cat_edges")
                                    .resizable()
                                    .interpolation(.none)
                                    .scaledToFit()

                                Image("cat_X")
                                    .resizable()
                                    .interpolation(.none)
                                    .scaledToFit()
                            }
                        }

                        Spacer()

                        Text(
                            "Here, we’re going to explore **convolutions**: a powerful mathematical operation used across many fields, including signal processing, image processing, and feature extraction in neural networks."
                        )
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .font(.customBody)

                        Spacer()

                        HStack {
                            Spacer()

                            Button {
                                isPressed = true
                            } label: {
                                Text("Next")
                                    .font(.customBody)
                                    .padding(10)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.vertical, 40)
                    .padding(.horizontal, 20)
                }
                .navigationDestination(isPresented: $isPressed) {
                    MathDefinitionView()
                }
            }
        }
    }
}

#Preview {
    IntroductionView()
}
