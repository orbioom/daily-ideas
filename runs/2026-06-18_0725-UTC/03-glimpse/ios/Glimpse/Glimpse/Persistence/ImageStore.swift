import UIKit
import ImageIO
import UniformTypeIdentifiers

/// File-based image store. Images live as JPEGs in `Documents/Glimpse/`;
/// SwiftData only ever holds the filename. Loads are downsampled for memory.
///
/// Every method is crash-proof: failures return nil / are ignored rather than
/// throwing into the UI. Missing files surface as nil so views can show a
/// graceful fallback.
final class ImageStore {
    static let shared = ImageStore()

    private let folderName = "Glimpse"
    private let fileManager = FileManager.default

    /// In-memory thumbnail cache keyed by "filename@pixelSize".
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 240
    }

    /// Documents/Glimpse, created on demand. Nil only if Documents is somehow
    /// unavailable (extremely unusual on iOS); callers treat that as "no image".
    private var directory: URL? {
        guard let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = docs.appendingPathComponent(folderName, isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func url(for filename: String) -> URL? {
        guard !filename.isEmpty else { return nil }
        return directory?.appendingPathComponent(filename, isDirectory: false)
    }

    func exists(_ filename: String?) -> Bool {
        guard let filename, let url = url(for: filename) else { return false }
        return fileManager.fileExists(atPath: url.path)
    }

    // MARK: - Saving

    /// Writes a JPEG (re-encoded, capped to a sane max dimension) and returns the
    /// generated filename, or nil on failure.
    func save(_ image: UIImage, maxDimension: CGFloat = 1600, quality: CGFloat = 0.82) -> String? {
        let resized = Self.resized(image, maxDimension: maxDimension)
        guard let data = resized.jpegData(compressionQuality: quality) else { return nil }
        let filename = "moment-\(UUID().uuidString).jpg"
        guard let dest = url(for: filename) else { return nil }
        do {
            try data.write(to: dest, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    /// Saves raw JPEG/PNG data (e.g. from PhotosPicker). Re-encodes to JPEG.
    func save(data: Data, maxDimension: CGFloat = 1600, quality: CGFloat = 0.82) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        return save(image, maxDimension: maxDimension, quality: quality)
    }

    func delete(_ filename: String?) {
        guard let filename, let url = url(for: filename) else { return }
        cache.removeAllObjects()
        try? fileManager.removeItem(at: url)
    }

    // MARK: - Loading

    /// Full-resolution load (used in detail). Nil if file is missing/corrupt.
    func loadFull(_ filename: String?) -> UIImage? {
        guard let filename, let url = url(for: filename),
              fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Downsampled thumbnail at the given point size (scaled by screen scale).
    func loadThumbnail(_ filename: String?, pointSize: CGFloat) -> UIImage? {
        guard let filename, let url = url(for: filename) else { return nil }
        let scale = UIScreen.main.scale
        let pixels = max(64, pointSize * scale)
        let cacheKey = NSString(string: "\(filename)@\(Int(pixels))")
        if let cached = cache.object(forKey: cacheKey) { return cached }

        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let srcOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, srcOptions as CFDictionary) else {
            return nil
        }
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: pixels
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
            return nil
        }
        let image = UIImage(cgImage: cg, scale: scale, orientation: .up)
        cache.setObject(image, forKey: cacheKey)
        return image
    }

    // MARK: - Helpers

    private static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return image }
        let scale = maxDimension / longest
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
