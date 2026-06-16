import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers

/// A PNG image wrapped for ShareLink. Built from an ImageRenderer-produced UIImage.
struct ShareableImage: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            item.image.pngData() ?? Data()
        }
        .suggestedFileName("encore-memory.png")
    }
}

/// Renders a SwiftUI view to a UIImage at the given scale, on the main actor.
@MainActor
enum ImageExport {
    static func render<V: View>(_ view: V, scale: CGFloat = 3) -> UIImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        return renderer.uiImage
    }
}
