//
//  ConvolutionOperationView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 12/02/26.
//

import SwiftUI

struct ConvolutionOperationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = ConvolutionAnimationViewModel()
    @State private var isPressed = false

    var body: some View {
        GeometryReader { geo in
            VStack {
                VStack {
                    Text("Operation")
                        .font(.system(size: 68))
                        .foregroundStyle(.cyan)

                    HStack {
                        Text(vm.stepText)
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                            .animation(.easeIn(duration: 0.25), value: vm.stepText)

                        Spacer()
                    }

                    Spacer()
                }
                .frame(height: geo.size.height * 0.2)

                ConvolutionAnimationView(vm: vm)


                HStack() {
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
            ConvolutionDemoView()
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    ConvolutionOperationView()
}
