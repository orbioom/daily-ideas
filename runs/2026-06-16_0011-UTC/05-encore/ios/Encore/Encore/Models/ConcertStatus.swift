import SwiftUI

/// Whether a show has happened (attended) or is still on the bucket list (wishlist).
enum ConcertStatus: String, Codable, CaseIterable, Identifiable {
    case attended = "Attended"
    case wishlist = "Wishlist"

    var id: String { rawValue }

    var display: String { rawValue }

    var symbol: String {
        switch self {
        case .attended: return "ticket.fill"
        case .wishlist: return "star.fill"
        }
    }
}

/// The kind of live event.
enum ConcertType: String, Codable, CaseIterable, Identifiable {
    case concert = "Concert"
    case festival = "Festival"

    var id: String { rawValue }

    var display: String { rawValue }

    var symbol: String {
        switch self {
        case .concert: return "music.mic"
        case .festival: return "tent.fill"
        }
    }
}
