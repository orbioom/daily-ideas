import SwiftUI

/// Renders the collage to a high-resolution UIImage using ImageRenderer. No
/// watermark — the export is exactly what you see.
enum Exporter {
    @MainActor
    static func render(model: EditorModel, longSide: CGFloat = 2000) -> UIImage? {
        let ratio = model.project.aspect.ratio
        let width: CGFloat
        let height: CGFloat
        if ratio >= 1 {
            width = longSide; height = longSide / ratio
        } else {
            height = longSide; width = longSide * ratio
        }
        let content = CollageCanvas(model: model, interactive: false)
            .frame(width: width, height: height)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        renderer.isOpaque = true
        return renderer.uiImage
    }
}

/// Presents the rendered image with Share and Save-to-Photos actions.
struct ExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    var onSaved: () -> Void
    @State private var saver = PhotoSaver()

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 18) {
                    Image(uiImage: image)
                        .resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Brand.cardShadow, radius: 16, y: 8)
                        .padding(.horizontal, 20)
                        .accessibilityLabel("Collage preview")

                    VStack(spacing: 12) {
                        ShareLink(item: Image(uiImage: image), preview: SharePreview("Mosaic collage", image: Image(uiImage: image))) {
                            Label("Share", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(InkButtonStyle())

                        Button {
                            saver.save(image) { ok in
                                if ok { onSaved(); dismiss() }
                            }
                        } label: {
                            Label("Save to Photos", systemImage: "square.and.arrow.down").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                    .padding(.horizontal, 24)

                    if let err = saver.error {
                        Text(err).font(.caption).foregroundStyle(Brand.danger)
                            .multilineTextAlignment(.center).padding(.horizontal, 24)
                    }
                }
                .padding(.vertical, 24)
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }
}

/// Writes an image to the photo library and reports success via a callback.
@Observable
final class PhotoSaver: NSObject {
    var error: String?
    private var completion: ((Bool) -> Void)?

    func save(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        self.completion = completion
        error = nil
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(didFinish(_:error:contextInfo:)), nil)
    }

    @objc private func didFinish(_ image: UIImage, error: Error?, contextInfo: UnsafeRawPointer) {
        if let error {
            self.error = "Couldn't save: \(error.localizedDescription). Check Photos permission in Settings."
            completion?(false)
        } else {
            Haptics.success()
            completion?(true)
        }
        completion = nil
    }
}
