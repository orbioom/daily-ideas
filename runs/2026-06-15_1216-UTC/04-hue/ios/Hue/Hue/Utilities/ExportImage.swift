import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers

/// A Transferable PNG wrapper so artworks can be shared via `ShareLink`.
struct ExportImage: Transferable {
    let uiImage: UIImage

    /// SwiftUI `Image` used for the share preview thumbnail.
    var image: Image { Image(uiImage: uiImage) }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { value in
            value.uiImage.pngData() ?? Data()
        }
        .suggestedFileName("Hue Artwork.png")
    }
}
