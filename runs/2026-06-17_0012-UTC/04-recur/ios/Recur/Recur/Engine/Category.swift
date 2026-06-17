import SwiftUI

/// A spending category for a subscription. Persisted by `rawValue`.
enum SubCategory: String, CaseIterable, Identifiable, Codable {
    case streaming
    case music
    case software
    case cloud
    case gaming
    case news
    case fitness
    case education
    case food
    case utilities
    case finance
    case shopping
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .streaming:    return "Streaming"
        case .music:        return "Music"
        case .software:     return "Software"
        case .cloud:        return "Cloud & Storage"
        case .gaming:       return "Gaming"
        case .news:         return "News"
        case .fitness:      return "Fitness"
        case .education:    return "Education"
        case .food:         return "Food & Drink"
        case .utilities:    return "Utilities"
        case .finance:      return "Finance"
        case .shopping:     return "Shopping"
        case .other:        return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .streaming:    return "play.tv"
        case .music:        return "music.note"
        case .software:     return "laptopcomputer"
        case .cloud:        return "icloud"
        case .gaming:       return "gamecontroller"
        case .news:         return "newspaper"
        case .fitness:      return "figure.run"
        case .education:    return "graduationcap"
        case .food:         return "fork.knife"
        case .utilities:    return "bolt"
        case .finance:      return "banknote"
        case .shopping:     return "bag"
        case .other:        return "square.grid.2x2"
        }
    }

    /// Default color hex used when seeding / classifying by category.
    var defaultHex: String {
        switch self {
        case .streaming:    return "E2574C"
        case .music:        return "1DB954"
        case .software:     return "7C5CF0"
        case .cloud:        return "3B9CF0"
        case .gaming:       return "9B59B6"
        case .news:         return "5D6D7E"
        case .fitness:      return "E67E22"
        case .education:    return "16A085"
        case .food:         return "E84393"
        case .utilities:    return "F1C40F"
        case .finance:      return "2EB0A0"
        case .shopping:     return "FD79A8"
        case .other:        return "8E8E93"
        }
    }

    /// Reconstructs from a stored raw value with a safe default.
    static func from(raw: String) -> SubCategory {
        SubCategory(rawValue: raw) ?? .other
    }
}
