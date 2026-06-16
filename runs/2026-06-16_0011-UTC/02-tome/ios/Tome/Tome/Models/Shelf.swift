import SwiftUI

/// Which shelf a book lives on. Stored as `rawValue` on `Book`.
enum Shelf: String, CaseIterable, Identifiable {
    case wantToRead
    case reading
    case finished
    case dnf

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wantToRead: return "Want to Read"
        case .reading: return "Reading"
        case .finished: return "Finished"
        case .dnf: return "Did Not Finish"
        }
    }

    /// Short label for compact segmented controls.
    var shortName: String {
        switch self {
        case .wantToRead: return "TBR"
        case .reading: return "Reading"
        case .finished: return "Finished"
        case .dnf: return "DNF"
        }
    }

    var symbol: String {
        switch self {
        case .wantToRead: return "bookmark"
        case .reading: return "book"
        case .finished: return "checkmark.seal"
        case .dnf: return "xmark.bin"
        }
    }

    var tint: Color {
        switch self {
        case .wantToRead: return Theme.inkSoft
        case .reading: return Theme.accent
        case .finished: return Theme.good
        case .dnf: return Theme.bad
        }
    }
}
