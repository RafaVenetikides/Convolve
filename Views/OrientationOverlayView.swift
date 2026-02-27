//
//  OrientationOverlayView.swift
//  Convolve
//
//  Created by Rafael Venetikides on 27/02/26.
//

import SwiftUI

struct OrientationOverlayView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color("backgroundColor").opacity(0.8))
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: "ipad")
                    .font(.system(size: 44, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)

                Text("Orientation not supported")
                    .font(.title2)
                    .bold()

                Text(
                    "Please, rotate your device to portrait for a better experience"
                )
                .font(.body)
                .multilineTextAlignment(.center)
            }
            .padding(22)
            .glassEffect(in: .rect(cornerRadius: 18))
        }
        .allowsHitTesting(true)
    }
}

#Preview {
    OrientationOverlayView()
}
