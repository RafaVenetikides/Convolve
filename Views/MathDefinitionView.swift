//
//  MathDefinitionView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 11/02/26.
//

import SwiftUI

struct MathDefinitionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPressed = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack {
                    Text("Definition")
                        .font(.system(size: 68))
                        .foregroundStyle(.cyan)
                        .padding(.bottom, 20)

                    Text(
                        "Formally, the **convolution** of two functions is represented by the following integral:"
                    )
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 28))

                    Spacer()

                    Image("Integral")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width * 0.6)

                    Spacer()

                    Text(
                        "It might look intimidating at first glance, but I promise if you stick here, we will find out that it's actually a pretty simple operation."
                    )
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 28))

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
            }
            .navigationDestination(isPresented: $isPressed) {
                ConvolutionOperationView()
            }
            .navigationBarBackButtonHidden()
        }
    }
}

#Preview {
    MathDefinitionView()
}
