import SwiftUI

/// The format a book is read in. Stored as `rawValue` on `Book`.
enum BookFormat: String, CaseIterable, Identifiable {
    case paperback
    case ebook
    case audiobook

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .paperback: return "Paperback"
        case .ebook: return "E-book"
        case .audiobook: return "Audiobook"
        }
    }

    var symbol: String {
        switch self {
        case .paperback: return "book.closed"
        case .ebook: return "ipad"
        case .audiobook: return "headphones"
        }
    }
}
