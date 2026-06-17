import SwiftUI

enum ExportError: LocalizedError {
    case renderFailed
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .renderFailed:
            return "Mural couldn't render this wallpaper. Try adjusting the design and exporting again."
        case .saveFailed(let detail):
            return "Saving to Photos failed: \(detail)"
        }
    }
}

/// Renders and saves wallpapers, honoring the Pro tier for high resolution and ultra-clean output.
@MainActor
enum ExportService {
    /// Produce a high-resolution UIImage for the given spec and aspect.
    /// Pro users get 4K and an optional grain-free render.
    static func renderExportImage(
        spec: WallpaperSpec,
        aspect: AspectRatioOption,
        isPro: Bool,
        ultraClean: Bool
    ) -> UIImage? {
        var working = spec
        if isPro && ultraClean {
            working.grain = 0
        }
        let size = (isPro ? aspect.exportSizeHighRes : aspect.exportSize)
        // ImageRenderer draws at point size; we pass the pixel size as points with scale 1.
        return WallpaperRenderer.renderImage(working, size: size, scale: 1)
    }

    /// Save an image to the photo library.
    static func saveToPhotos(_ image: UIImage) async throws {
        let saver = PhotoSaver()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            saver.save(image) { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    continuation.resume(throwing: ExportError.saveFailed(error.localizedDescription))
                }
            }
        }
    }
}
