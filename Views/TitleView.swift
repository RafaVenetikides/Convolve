//
//  TitleView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 25/02/26.
//

import SwiftUI

struct TitleView: View {
    @EnvironmentObject private var router: NavRouter
    @State private var isSpinning = false

    var body: some View {
        ZStack {
            Color(.background)
                .ignoresSafeArea()

            VStack {
                Spacer()

                Text("TITULO MUITO FODA!!!!!!!!!")
                    .foregroundStyle(.white)
                    .font(.system(size: 100, weight: .bold))
                    .rotationEffect(.degrees(isSpinning ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isSpinning)
                    .onAppear {
                        isSpinning = true
                    }

                Spacer()

                Button{
                    router.push(.intro)
                } label: {
                    Text("COMERÇAR")
                        .foregroundStyle(.white)
                        .font(.system(size: 30, weight: .bold))
                        .padding(10)
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    TitleView()
}
