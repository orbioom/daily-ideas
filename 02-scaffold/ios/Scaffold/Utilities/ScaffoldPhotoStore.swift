import UIKit
import Foundation

final class ScaffoldPhotoStore {
    static let shared = ScaffoldPhotoStore()
    private let directory: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directory = docs.appendingPathComponent("ScaffoldPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func save(_ image: UIImage, filename: String) throws {
        guard let data = image.jpegData(compressionQuality: 0.75) else { return }
        try data.write(to: directory.appendingPathComponent(filename))
    }

    func load(filename: String) -> UIImage? {
        guard let data = try? Data(contentsOf: directory.appendingPathComponent(filename)) else { return nil }
        return UIImage(data: data)
    }

    func delete(filename: String) {
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(filename))
    }

    func newFilename() -> String { UUID().uuidString + ".jpg" }
}
