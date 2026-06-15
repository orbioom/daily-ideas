import SwiftUI

/// Renders a small PNG thumbnail of a page+fills off the interactive path.
@MainActor
enum ThumbnailRenderer {
    static func render(page: ColoringPage, fills: [Int: String], palette: Palette,
                       size: CGFloat = 240) -> Data? {
        let view = PageCanvasView(page: page, fills: fills, palette: palette,
                                  showOutlines: true, showNumbers: false)
            .frame(width: size, height: size)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let ui = renderer.uiImage else { return nil }
        return ui.pngData()
    }
}
