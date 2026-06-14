import Foundation

/// Playback speed in revolutions per minute. Stored as rawValue on the model.
enum Speed: String, Codable, CaseIterable, Identifiable {
    case rpm33 = "33⅓ RPM"
    case rpm45 = "45 RPM"
    case rpm78 = "78 RPM"

    var id: String { rawValue }

    var display: String { rawValue }

    /// Compact label used on badges (e.g. "33").
    var shortLabel: String {
        switch self {
        case .rpm33: return "33⅓"
        case .rpm45: return "45"
        case .rpm78: return "78"
        }
    }
}
