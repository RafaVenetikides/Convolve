//
//  IntroductionView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 10/02/26.
//

import SwiftUI

struct IntroductionView: View {
    @EnvironmentObject private var router: NavRouter

    var body: some View {
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
                        "Take a look at the 4 images below. The same technique used to create these diferent effects from the original picture is a key building block of modern AI. It's how neural networks can make of what's in an image."
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
                    .padding(.vertical, 20)

                    Spacer()

                    Text(
                        "Here, we’re going to explore the world of **convolutions**: a powerful mathematical operation used across many fields, including signal processing, image processing, and feature extraction in neural networks."
                    )
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .font(.customBody)

                    Spacer()

                    HStack {
                        Spacer()

                        Button {
                            router.push(.mathDefinition)
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
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    IntroductionView()
}
