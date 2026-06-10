import UIKit

/// Stores collage images as JPEGs in Documents/MosaicImages. Images never live
/// in SwiftData or the cloud — they stay on disk, on this device.
enum ImageStore {
    private static var dir: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let d = base.appendingPathComponent("MosaicImages", isDirectory: true)
        if !FileManager.default.fileExists(atPath: d.path) {
            try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        }
        return d
    }

    /// Downscale to a sane editing/export size so memory and Core Image stay fast.
    static func downscale(_ image: UIImage, maxDimension: CGFloat = 1600) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return image }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }

    /// Save an image, returning its filename. Returns nil on failure.
    @discardableResult
    static func save(_ image: UIImage, quality: CGFloat = 0.9) -> String? {
        let scaled = downscale(image)
        guard let data = scaled.jpegData(compressionQuality: quality) else { return nil }
        let name = UUID().uuidString + ".jpg"
        do {
            try data.write(to: dir.appendingPathComponent(name))
            return name
        } catch {
            return nil
        }
    }

    static func saveThumbnail(_ image: UIImage) -> String? {
        let thumb = downscale(image, maxDimension: 400)
        guard let data = thumb.jpegData(compressionQuality: 0.8) else { return nil }
        let name = "thumb_" + UUID().uuidString + ".jpg"
        do {
            try data.write(to: dir.appendingPathComponent(name))
            return name
        } catch { return nil }
    }

    static func load(_ filename: String?) -> UIImage? {
        guard let filename else { return nil }
        let url = dir.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func delete(_ filename: String?) {
        guard let filename else { return }
        try? FileManager.default.removeItem(at: dir.appendingPathComponent(filename))
    }
}
