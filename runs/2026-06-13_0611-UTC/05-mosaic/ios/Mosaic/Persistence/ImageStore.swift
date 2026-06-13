import UIKit

/// Stores day photos as JPEGs in the app's Documents directory.
/// Photos never live in SwiftData or iCloud — only their filenames are persisted.
enum ImageStore {
    private static var folder: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("photos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Save a downscaled JPEG, returning its filename, or nil on failure.
    static func save(_ image: UIImage) -> String? {
        let resized = downscale(image, maxDimension: 1600)
        guard let data = resized.jpegData(compressionQuality: 0.82) else { return nil }
        let name = UUID().uuidString + ".jpg"
        let url = folder.appendingPathComponent(name)
        do { try data.write(to: url, options: .atomic); return name }
        catch { return nil }
    }

    static func load(_ name: String?) -> UIImage? {
        guard let name else { return nil }
        return UIImage(contentsOfFile: folder.appendingPathComponent(name).path)
    }

    static func delete(_ name: String?) {
        guard let name else { return }
        try? FileManager.default.removeItem(at: folder.appendingPathComponent(name))
    }

    private static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
