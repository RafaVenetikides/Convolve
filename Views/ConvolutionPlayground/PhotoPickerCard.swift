//
//  PhotoPickerCard.swift
//  Convolve
//
//  Created by Rafael Venetikides on 27/02/26.
//

import SwiftUI

struct PhotoPickerCard: View {
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white.opacity(0.04))
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.white.opacity(0.10), lineWidth: 1)
                    )

                VStack(spacing: 12) {
                    Image(systemName: isLoading ? "hourglass" : "photo.on.rectangle.angled")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.cyan)

                    Text(isLoading ? "Loading..." : "From Photos")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.95))
                }
                .opacity(16)
            }

            Text("Use your own image")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }
}

#Preview {
    PhotoPickerCard(isLoading: false)
}
