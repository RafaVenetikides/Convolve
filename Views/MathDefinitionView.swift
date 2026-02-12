//
//  MathDefinitionView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 11/02/26.
//

import SwiftUI

struct MathDefinitionView: View {
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
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
            }
            .onTapGesture {
                isPressed = true
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
