import Foundation
import Photos
import UIKit

enum GroupKind: String, Identifiable {
    case month, screenshots, videos, similar
    var id: String { rawValue }

    var title: String {
        switch self {
        case .month: return "By Month"
        case .screenshots: return "Screenshots"
        case .videos: return "Videos"
        case .similar: return "Similar Shots"
        }
    }
    var icon: String {
        switch self {
        case .month: return "calendar"
        case .screenshots: return "camera.viewfinder"
        case .videos: return "video.fill"
        case .similar: return "square.stack.3d.down.right.fill"
        }
    }
}

/// A reviewable bundle of assets (a month, all screenshots, etc.).
struct PhotoGroup: Identifiable, Hashable {
    let id: String
    let kind: GroupKind
    let title: String
    let assets: [PHAsset]
    var estimatedBytes: Int64
    var cover: PHAsset? { assets.first }
    var count: Int { assets.count }

    static func == (lhs: PhotoGroup, rhs: PhotoGroup) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Owns all interaction with the photo library: authorization, scanning into
/// reviewable groups, thumbnails, size estimates, and deletion.
@MainActor
final class PhotoLibraryService: ObservableObject {
    @Published var status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @Published var isScanning = false
    @Published var groups: [PhotoGroup] = []
    @Published var totalPhotos = 0
    @Published var totalVideos = 0
    @Published var estimatedLibraryBytes: Int64 = 0
    @Published var basket: [PHAsset] = []

    private let imageManager = PHCachingImageManager()
    private var keptIdentifiers: Set<String> = []

    var isAuthorized: Bool { status == .authorized || status == .limited }

    var basketBytes: Int64 { basket.reduce(0) { $0 + Self.estimatedBytes($1) } }

    func isMarked(_ asset: PHAsset) -> Bool {
        basket.contains { $0.localIdentifier == asset.localIdentifier }
    }

    func mark(_ asset: PHAsset) {
        guard !isMarked(asset) else { return }
        basket.append(asset)
    }

    func unmark(_ asset: PHAsset) {
        basket.removeAll { $0.localIdentifier == asset.localIdentifier }
    }

    func clearBasket() { basket.removeAll() }

    func refreshStatus() {
        status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAccess() async {
        let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        status = newStatus
    }

    /// Estimated bytes for an asset based on its dimensions / duration.
    nonisolated static func estimatedBytes(_ asset: PHAsset) -> Int64 {
        if asset.mediaType == .video {
            return max(2_000_000, Int64(asset.duration * 2_500_000))
        }
        let pixels = Double(asset.pixelWidth) * Double(asset.pixelHeight)
        return max(200_000, Int64(pixels * 0.30))
    }

    /// Scan the library and build review groups, excluding kept photos.
    func scan(kept: [String]) async {
        guard isAuthorized else { return }
        isScanning = true
        keptIdentifiers = Set(kept)
        defer { isScanning = false }

        // Run the fetch off the main thread; PHFetchResult access is thread-safe.
        let result = await Task.detached(priority: .userInitiated) { [keptIdentifiers] in
            Self.buildGroups(excluding: keptIdentifiers)
        }.value

        self.groups = result.groups
        self.totalPhotos = result.photos
        self.totalVideos = result.videos
        self.estimatedLibraryBytes = result.bytes
    }

    private struct ScanResult {
        var groups: [PhotoGroup]
        var photos: Int
        var videos: Int
        var bytes: Int64
    }

    nonisolated private static func buildGroups(excluding kept: Set<String>) -> ScanResult {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let all = PHAsset.fetchAssets(with: options)

        var images: [PHAsset] = []
        var screenshots: [PHAsset] = []
        var videos: [PHAsset] = []
        var totalBytes: Int64 = 0
        var photoCount = 0
        var videoCount = 0

        all.enumerateObjects { asset, _, _ in
            totalBytes += estimatedBytes(asset)
            if asset.mediaType == .video {
                videoCount += 1
                if !kept.contains(asset.localIdentifier) { videos.append(asset) }
            } else if asset.mediaType == .image {
                photoCount += 1
                if kept.contains(asset.localIdentifier) { return }
                if asset.mediaSubtypes.contains(.photoScreenshot) {
                    screenshots.append(asset)
                } else {
                    images.append(asset)
                }
            }
        }

        var groups: [PhotoGroup] = []

        // By month (newest first).
        let cal = Calendar.current
        let byMonth = Dictionary(grouping: images) { asset -> DateComponents in
            cal.dateComponents([.year, .month], from: asset.creationDate ?? .distantPast)
        }
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "LLLL yyyy"
        for (comps, assets) in byMonth.sorted(by: { ($0.key.year ?? 0, $0.key.month ?? 0) > ($1.key.year ?? 0, $1.key.month ?? 0) }) {
            guard let date = cal.date(from: comps) else { continue }
            let bytes = assets.reduce(Int64(0)) { $0 + estimatedBytes($1) }
            groups.append(PhotoGroup(id: "month-\(comps.year ?? 0)-\(comps.month ?? 0)",
                                     kind: .month, title: monthFormatter.string(from: date),
                                     assets: assets, estimatedBytes: bytes))
        }

        // Screenshots.
        if !screenshots.isEmpty {
            let bytes = screenshots.reduce(Int64(0)) { $0 + estimatedBytes($1) }
            groups.insert(PhotoGroup(id: "screenshots", kind: .screenshots, title: "Screenshots",
                                     assets: screenshots, estimatedBytes: bytes), at: 0)
        }

        // Similar shots: runs of >= 2 photos taken within 8 seconds of each other.
        let similar = findSimilar(in: images, withinSeconds: 8)
        if !similar.isEmpty {
            let bytes = similar.reduce(Int64(0)) { $0 + estimatedBytes($1) }
            groups.insert(PhotoGroup(id: "similar", kind: .similar, title: "Similar Shots",
                                     assets: similar, estimatedBytes: bytes), at: 0)
        }

        // Videos last (often biggest).
        if !videos.isEmpty {
            let bytes = videos.reduce(Int64(0)) { $0 + estimatedBytes($1) }
            groups.append(PhotoGroup(id: "videos", kind: .videos, title: "Videos",
                                     assets: videos, estimatedBytes: bytes))
        }

        return ScanResult(groups: groups, photos: photoCount, videos: videoCount, bytes: totalBytes)
    }

    /// Flattens runs of near-simultaneous photos (likely duplicates) into one pool.
    nonisolated private static func findSimilar(in images: [PHAsset], withinSeconds gap: TimeInterval) -> [PHAsset] {
        let sorted = images.sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
        var result: [PHAsset] = []
        var run: [PHAsset] = []
        var last: Date?
        func flush() {
            if run.count >= 2 { result.append(contentsOf: run) }
            run.removeAll()
        }
        for asset in sorted {
            let date = asset.creationDate ?? .distantPast
            if let l = last, date.timeIntervalSince(l) <= gap {
                run.append(asset)
            } else {
                flush()
                run = [asset]
            }
            last = date
        }
        flush()
        return result
    }

    /// Request a thumbnail for an asset.
    func thumbnail(for asset: PHAsset, size: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            // highQualityFormat invokes the handler exactly once, so the
            // continuation is resumed exactly once.
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    /// Delete the given assets; the system shows a confirmation dialog.
    func delete(_ assets: [PHAsset]) async -> Bool {
        guard !assets.isEmpty else { return false }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }
            return true
        } catch {
            return false
        }
    }
}
