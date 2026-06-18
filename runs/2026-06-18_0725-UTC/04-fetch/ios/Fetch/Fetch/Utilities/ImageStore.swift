import UIKit

/// Saves dog photos to the app's Documents directory and returns only the filename
/// (we persist the filename in SwiftData, never the raw blob). All paths are guarded.
enum ImageStore {
    private static var directory: URL? {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let dir = docs.appendingPathComponent("DogPhotos", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Saves JPEG data, returns the generated filename or nil on failure.
    static func save(_ image: UIImage) -> String? {
        guard let dir = directory else { return nil }
        guard let data = image.jpegData(compressionQuality: 0.82) else { return nil }
        let filename = "dog-\(UUID().uuidString).jpg"
        let url = dir.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    /// Loads an image for a filename. Returns nil gracefully if missing.
    static func load(_ filename: String?) -> UIImage? {
        guard let filename, !filename.isEmpty, let dir = directory else { return nil }
        let url = dir.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    static func delete(_ filename: String?) {
        guard let filename, !filename.isEmpty, let dir = directory else { return }
        let url = dir.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}
