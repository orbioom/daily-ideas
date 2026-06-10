import SwiftUI
import UIKit
import Photos

/// Loads an asset thumbnail asynchronously with a calm placeholder.
struct ThumbnailView: View {
    let asset: PHAsset
    var targetSize: CGSize = CGSize(width: 400, height: 400)
    @EnvironmentObject private var library: PhotoLibraryService
    @State private var image: UIImage?
    @State private var loaded = false

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Brand.mist2)
                    .overlay {
                        if !loaded {
                            ProgressView().tint(Brand.text3)
                        } else {
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundStyle(Brand.text3)
                        }
                    }
            }
        }
        .task(id: asset.localIdentifier) {
            image = await library.thumbnail(for: asset, size: targetSize)
            loaded = true
        }
        .accessibilityHidden(true)
    }
}
