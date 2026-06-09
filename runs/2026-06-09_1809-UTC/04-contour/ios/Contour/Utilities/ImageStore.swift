import UIKit

/// On-device-only image store. Saves UIImages as JPEG into
/// `Documents/Photos/<uuid>.jpg`, loads them back by filename, and deletes them.
/// Nothing here ever touches SwiftData blobs or the network — this is Contour's
/// privacy wedge: progress photos live only on this device. Every throwing call
/// is handled with try?/do-catch and a missing file returns nil, never a crash.
enum ImageStore {

    private static let folderName = "Photos"

    /// The `Documents/Photos` directory, created on demand. Returns nil if the
    /// directory can't be resolved or created.
    private static func photosDirectory() -> URL? {
        guard let docs = FileManager.default.urls(for: .documentDirectory,
                                                  in: .userDomainMask).first else {
            return nil
        }
        let dir = docs.appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            do {
                try FileManager.default.createDirectory(at: dir,
                                                        withIntermediateDirectories: true)
            } catch {
                return nil
            }
        }
        return dir
    }

    private static func url(for filename: String) -> URL? {
        guard !filename.isEmpty, let dir = photosDirectory() else { return nil }
        return dir.appendingPathComponent(filename, isDirectory: false)
    }

    /// Saves the image as JPEG and returns its generated filename ("<uuid>.jpg"),
    /// or nil if encoding or writing failed.
    @discardableResult
    static func save(_ image: UIImage, quality: CGFloat = 0.85) -> String? {
        guard let data = image.jpegData(compressionQuality: quality) else { return nil }
        let filename = "\(UUID().uuidString).jpg"
        guard let target = url(for: filename) else { return nil }
        do {
            try data.write(to: target, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    /// Loads an image by filename. Returns nil gracefully if the file is missing
    /// or unreadable — callers show a calm fallback tile instead.
    static func load(_ filename: String) -> UIImage? {
        guard let source = url(for: filename) else { return nil }
        guard let data = try? Data(contentsOf: source) else { return nil }
        return UIImage(data: data)
    }

    /// Deletes the file for a filename. No-op if it doesn't exist.
    static func delete(_ filename: String) {
        guard let target = url(for: filename) else { return }
        try? FileManager.default.removeItem(at: target)
    }

    /// Removes every stored image file. Used by Settings' "delete all" action.
    static func deleteAll() {
        guard let dir = photosDirectory() else { return }
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil)) ?? []
        for file in contents {
            try? FileManager.default.removeItem(at: file)
        }
    }
}
