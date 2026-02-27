//
//  PlaygroundCollectionView.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 19/02/26.
//

import SwiftUI
import PhotosUI

struct PlaygroundCollectionView: View {
    @EnvironmentObject private var router: NavRouter

    @State private var pickedItem: PhotosPickerItem?
    @State private var isLoadingPhoto = false

    private let assets: [DemoAsset] = [
        .init(assetName: "seven", title: "Hand drawn seven"),
        .init(assetName: "cat", title: "Black cat"),
        .init(assetName: "moon", title: "Moon"),
        .init(assetName: "flower", title: "Flower")
    ]

    private let columns = [
        GridItem(.adaptive(minimum: 270), spacing: 30)
    ]

    var body: some View {
        ZStack {
            Color("backgroundColor")
                .ignoresSafeArea()

            VStack {
                Text("Choose an image")
                    .font(.system(size: 68))
                    .bold()
                    .foregroundStyle(.cyan)
                    .padding(.bottom, 20)

                Text("Pick an example to apply kernels and watch the scan in convolution in real time.")
                    .font(.system(size: 24))
                    .foregroundStyle(.white.opacity(0.9))


                ScrollView {
                    LazyVGrid(columns: columns, spacing: 30) {
                        ForEach(assets) { item in
                            Button {
                                router.push(.convolution(assetName: item.assetName))
                            } label: {
                                AssetCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }

                        PhotosPicker(
                            selection: $pickedItem,
                            matching: .images,
                            photoLibrary: .shared()) {
                                PhotoPickerCard(isLoading: isLoadingPhoto)
                            }
                            .buttonStyle(.plain)
                            .disabled(isLoadingPhoto)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 60)
                }

                Spacer()

                HStack {
                    Button {
                        router.pop()
                        } label: {
                            Text("Back")
                                .font(.system(size: 24))
                                .padding()
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                }
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 20)
        }
        .toolbar(content: {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.goHome()
                } label: {
                    Image(systemName: "house.fill")
                        .foregroundStyle(.tint)
                }
            }
        })
        .navigationBarBackButtonHidden()
        .onChange(of: pickedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                isLoadingPhoto = true
                defer { isLoadingPhoto = false }

                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    router.push(.convolutionPhoto(imageData: data))
                }

                pickedItem = nil
            }
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
                .padding(12)

            Text(item.title)
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
    NavigationStack {
        PlaygroundCollectionView()
            .environmentObject(NavRouter())
    }
}
