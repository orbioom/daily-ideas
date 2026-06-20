import UIKit
import Foundation

enum PhotoStoreError: Error {
    case failedToSave
    case notFound
}

final class PhotoStore {
    static let shared = PhotoStore()
    private let directory: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directory = docs.appendingPathComponent("KinPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func save(_ image: UIImage, filename: String) throws {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw PhotoStoreError.failedToSave
        }
        let url = directory.appendingPathComponent(filename)
        try data.write(to: url)
    }

    func load(filename: String) -> UIImage? {
        let url = directory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func delete(filename: String) {
        let url = directory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }

    func newFilename() -> String {
        UUID().uuidString + ".jpg"
    }
}
