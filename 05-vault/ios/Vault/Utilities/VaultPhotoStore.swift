import UIKit
import CryptoKit

final class VaultPhotoStore {
    static let shared = VaultPhotoStore()
    private init() { try? FileManager.default.createDirectory(at: storageURL, withIntermediateDirectories: true) }

    private var storageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VaultPhotos", isDirectory: true)
    }

    func save(_ image: UIImage, quality: CGFloat = 0.85) -> String? {
        guard let data = image.jpegData(compressionQuality: quality) else { return nil }
        let fileID = UUID().uuidString
        let url = storageURL.appendingPathComponent("\(fileID).jpg")
        try? data.write(to: url)
        return fileID
    }

    func load(_ fileID: String) -> UIImage? {
        let url = storageURL.appendingPathComponent("\(fileID).jpg")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func thumbnail(_ fileID: String, size: CGFloat = 200) -> UIImage? {
        guard let img = load(fileID) else { return nil }
        let scale = size / max(img.size.width, img.size.height)
        let newSize = CGSize(width: img.size.width * scale, height: img.size.height * scale)
        return UIGraphicsImageRenderer(size: newSize).image { _ in img.draw(in: CGRect(origin: .zero, size: newSize)) }
    }

    func delete(_ fileID: String) {
        let url = storageURL.appendingPathComponent("\(fileID).jpg")
        try? FileManager.default.removeItem(at: url)
    }

    func storageUsedMB() -> Double {
        let files = (try? FileManager.default.contentsOfDirectory(at: storageURL, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        let total = files.compactMap { try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize }.reduce(0, +)
        return Double(total) / 1_048_576
    }
}

// Simple PIN hashing (SHA256 of PIN string)
extension String {
    func vaultPINHash() -> String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
