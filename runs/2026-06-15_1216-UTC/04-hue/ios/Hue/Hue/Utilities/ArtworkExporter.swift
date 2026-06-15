import SwiftUI

/// Renders a high-resolution export image of an artwork, optionally watermarked.
@MainActor
enum ArtworkExporter {
    static func render(page: ColoringPage, fills: [Int: String], palette: Palette,
                       watermark: Bool, size: CGFloat = 1024) -> UIImage? {
        let view = ExportCanvas(page: page, fills: fills, palette: palette,
                                watermark: watermark, side: size)
            .frame(width: size, height: size)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        return renderer.uiImage
    }
}

private struct ExportCanvas: View {
    let page: ColoringPage
    let fills: [Int: String]
    let palette: Palette
    let watermark: Bool
    let side: CGFloat

    var body: some View {
        ZStack {
            Color(hex: 0xFFFFFF)
            PageCanvasView(page: page, fills: fills, palette: palette,
                           showOutlines: true, showNumbers: false)
            if watermark {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Made with Hue")
                            .font(.system(size: side * 0.028, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: 0x9A8FA1))
                            .padding(.horizontal, side * 0.02)
                            .padding(.vertical, side * 0.012)
                            .background(
                                Capsule().fill(Color(hex: 0xFFFFFF).opacity(0.85))
                            )
                            .padding(side * 0.03)
                    }
                }
            }
        }
        .frame(width: side, height: side)
    }
}
