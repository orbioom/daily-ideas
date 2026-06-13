import SwiftUI
import UIKit
import CoreImage

@MainActor
@Observable
final class EditorModel {
    var displayImage: UIImage?
    var originalPreview: UIImage?
    var adjustments = Adjustments()
    var activePresetName: String? = "Original"
    var isProcessing = false

    private var fullSource: CIImage?
    private var previewSource: CIImage?
    private var thumbSource: CIImage?
    private var processTask: Task<Void, Never>?

    var hasImage: Bool { fullSource != nil }
    var isEdited: Bool { !adjustments.isNeutral }

    func load(data: Data) async {
        guard let ui = UIImage(data: data) else { return }
        let normalized = Self.normalized(ui)
        guard let ci = CIImage(image: normalized) else { return }
        fullSource = ci
        let preview = ImageEngine.shared.downscaled(ci, maxDimension: 1400)
        previewSource = preview
        thumbSource = ImageEngine.shared.downscaled(ci, maxDimension: 150)
        adjustments = .neutral
        activePresetName = "Original"
        originalPreview = ImageEngine.shared.render(preview)
        process()
    }

    /// Small previews of each preset applied to the loaded photo, rendered off-main.
    func presetThumbnails(_ presets: [Preset]) async -> [String: UIImage] {
        guard let src = thumbSource else { return [:] }
        return await Task.detached(priority: .utility) {
            var out: [String: UIImage] = [:]
            for p in presets {
                if let ui = ImageEngine.shared.processed(source: src, adjustments: p.adjustments) {
                    out[p.id] = ui
                }
            }
            return out
        }.value
    }

    func apply(preset: Preset) {
        adjustments = preset.adjustments
        activePresetName = preset.name
        Haptics.tap()
        process()
    }

    func setField(_ field: Adjustments.Field, _ value: Double) {
        adjustments[field] = value
        activePresetName = nil
        process()
    }

    func resetAll() {
        adjustments = .neutral
        activePresetName = "Original"
        Haptics.soft()
        process()
    }

    func clearImage() {
        processTask?.cancel()
        fullSource = nil; previewSource = nil
        displayImage = nil; originalPreview = nil
        adjustments = .neutral; activePresetName = "Original"
    }

    /// Re-render the live preview, off the main thread, cancelling stale work.
    private func process() {
        guard let src = previewSource else { return }
        let adj = adjustments
        processTask?.cancel()
        isProcessing = true
        processTask = Task { [weak self] in
            let ui = await Task.detached(priority: .userInitiated) {
                ImageEngine.shared.processed(source: src, adjustments: adj)
            }.value
            guard let self, !Task.isCancelled else { return }
            if let ui { self.displayImage = ui }
            self.isProcessing = false
        }
    }

    /// Full-resolution render for export.
    func exportImage() -> UIImage? {
        guard let src = fullSource else { return nil }
        return ImageEngine.shared.processed(source: src, adjustments: adjustments)
    }

    private static func normalized(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: image.size)) }
    }
}
