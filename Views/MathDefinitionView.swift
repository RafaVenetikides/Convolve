//
//  MathDefinitionView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 11/02/26.
//

import SwiftUI

struct MathDefinitionView: View {
    @EnvironmentObject private var router: NavRouter

    private enum Focus: Hashable { case title, next }
    @AccessibilityFocusState private var focus: Focus?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color("backgroundColor")
                    .ignoresSafeArea()

                VStack {
                    Text("Definition")
                        .font(.customTitle)
                        .bold()
                        .foregroundStyle(.cyan)
                        .padding(.bottom, 20)

                    Text(
                        "Formally, the **convolution** of two functions is represented by the following integral:"
                    )
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .font(.customBody)

                    Spacer()

                    VStack {
                        Image("Integral")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.6)
                            .accessibilityElement(children: .ignore)
                            .accessibilityAddTraits(.isImage)
                            .accessibilityLabel("Convolution definition")
                            .accessibilityValue(
                                "Integral from negative infinity to infinity of f of tau times g of t minus tau, d tau."
                            )


                        Text(
                            "It might look intimidating at first glance, but I promise if you stick here, we will find out that it's actually a pretty simple operation."
                        )
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .font(.customBodySmall)
                        .frame(width: geo.size.width * 0.7)

                    }
                    .padding(20)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white)
                    }

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
                        .accessibilityLabel("Back")
                        .accessibilityHint("Returns to the previous screen.")

                        Spacer()

                        Button {
                            router.push(.operation)
                        } label: {
                            Text("Next")
                                .font(.system(size: 24))
                                .padding(10)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Next")
                        .accessibilityHint("Opens the convolution operation.")
                        .accessibilityFocused($focus, equals: .next)

                    }
                    .padding(.top, 20)
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
            }
            .navigationBarBackButtonHidden()
        }
    }
}

#Preview {
    MathDefinitionView()
}
