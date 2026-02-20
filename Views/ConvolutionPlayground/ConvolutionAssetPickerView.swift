//
//  ConvolutionAssetPickerView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 19/02/26.
//

import SwiftUI

struct ConvolutionAssetPickerView: View {
    @Environment(\.dismiss) private var dismiss

    private let assets: [DemoAsset] = [
        .init(assetName: "seven", title: "Hand drawn seven"),
        .init(assetName: "cat", title: "Black cat"),
        .init(assetName: "moon", title: "Moon"),
    ]

    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Text("Choose an image")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.cyan)

                Text("Pick an example to apply kernels and watch the scan in convolution in real time.")
                    .font(.system(size: 24))
                    .foregroundStyle(.white.opacity(0.9))


                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(assets) { item in
                            NavigationLink {
                                ConvolutionDemoView(assetName: item.assetName)
                            } label: {
                                AssetCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 20)
        }
    }
}

struct AssetCard: View {
    let item: DemoAsset

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(item.assetName)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )

            Text(item.title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
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
    ConvolutionAssetPickerView()
}
