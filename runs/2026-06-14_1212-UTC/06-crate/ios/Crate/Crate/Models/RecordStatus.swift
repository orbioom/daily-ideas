import Foundation

/// Whether a record is in the collection or on the wantlist.
enum RecordStatus: String, Codable, CaseIterable, Identifiable {
    case owned = "Owned"
    case wishlist = "Wantlist"

    var id: String { rawValue }

    var display: String { rawValue }

    var symbol: String {
        switch self {
        case .owned: return "checkmark.seal.fill"
        case .wishlist: return "bookmark.fill"
        }
    }
}
