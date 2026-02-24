//
//  PlaygroundIntroductionView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 19/02/26.
//

import SwiftUI

struct PlaygroundIntroductionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPressed: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.background)
                    .ignoresSafeArea()

                VStack {
                    Text("Experiment time")
                        .font(.system(size: 68))
                        .bold()
                        .foregroundStyle(.cyan)
                        .padding(.bottom, 20)

                    VStack(alignment: .leading) {
                        Text(
                            "That was just a small introduction to the vast field of the convolutions, there is a lot more areas that utilize this operation, like probability/statistics, signal processing, physics, and so on."
                        )
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, geo.size.height * 0.03)

                        Text(
                            "Now you will enter a playground where you can play around with convolution in diferent images and se their diferent results using diferent kernels. Feel free to explore and play as you like."
                        )
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Button {
                        isPressed = true
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 24))
                            .padding(10)

                            .foregroundStyle(.white)
                        Text("Playground")
                            .font(.system(size: 24))
                            .padding(10)
                    }
                    .buttonStyle(.borderedProminent)

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
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
                .navigationDestination(isPresented: $isPressed) {
                    PlaygroundCollectionView()
                }
                .navigationBarBackButtonHidden()
            }
        }
    }
}

#Preview {
    PlaygroundIntroductionView()
}
