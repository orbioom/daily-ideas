import Foundation

/// Physical film format of a roll. Stored as a raw string for tolerant decoding.
enum FilmFormat: String, CaseIterable, Identifiable, Codable, Sendable {
    case format35mm = "35mm"
    case medium120 = "120"
    case sheet4x5 = "4x5"
    case format110 = "110"
    case digital = "Digital"

    var id: String { rawValue }

    var title: String { rawValue }

    /// Typical number of frames per roll (used only for progress hints; sheet film is open-ended).
    var typicalFrames: Int {
        switch self {
        case .format35mm: return 36
        case .medium120:  return 12
        case .sheet4x5:   return 1
        case .format110:  return 24
        case .digital:    return 0
        }
    }

    var systemImage: String {
        switch self {
        case .format35mm, .format110: return "film"
        case .medium120:              return "film.stack"
        case .sheet4x5:               return "rectangle.portrait"
        case .digital:                return "camera"
        }
    }
}

/// Measurement units preference (affects how focal length & distance hints read).
enum UnitSystem: String, CaseIterable, Identifiable, Codable, Sendable {
    case metric, imperial

    var id: String { rawValue }

    var title: String {
        switch self {
        case .metric:   return "Metric"
        case .imperial: return "Imperial"
        }
    }
}
