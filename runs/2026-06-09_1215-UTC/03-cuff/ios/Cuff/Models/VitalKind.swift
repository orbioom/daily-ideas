import SwiftUI

/// The metrics Cuff can log. Each maps to a SF Symbol, an accent token, and the
/// canonical unit string used internally (display units come from Settings).
enum VitalKind: String, CaseIterable, Identifiable, Codable {
    case bloodPressure, weight, glucose, spo2, pulse

    var id: String { rawValue }

    var label: String {
        switch self {
        case .bloodPressure: return "Blood pressure"
        case .weight:        return "Weight"
        case .glucose:       return "Blood glucose"
        case .spo2:          return "Oxygen (SpO₂)"
        case .pulse:         return "Pulse"
        }
    }

    /// A short label for tight spaces (tiles, segmented pickers).
    var shortLabel: String {
        switch self {
        case .bloodPressure: return "BP"
        case .weight:        return "Weight"
        case .glucose:       return "Glucose"
        case .spo2:          return "SpO₂"
        case .pulse:         return "Pulse"
        }
    }

    var symbol: String {
        switch self {
        case .bloodPressure: return "heart.fill"
        case .weight:        return "scalemass.fill"
        case .glucose:       return "drop.fill"
        case .spo2:          return "lungs.fill"
        case .pulse:         return "waveform.path.ecg"
        }
    }

    var tint: Color {
        switch self {
        case .bloodPressure: return Brand.danger
        case .weight:        return Brand.info
        case .glucose:       return Brand.warn
        case .spo2:          return Brand.live
        case .pulse:         return Brand.magic
        }
    }
}

/// When a reading was taken — drives morning vs evening BP averages.
enum TimeTag: String, CaseIterable, Identifiable, Codable {
    case morning, afternoon, evening, night, unspecified

    var id: String { rawValue }

    var label: String {
        switch self {
        case .morning:     return "Morning"
        case .afternoon:   return "Afternoon"
        case .evening:     return "Evening"
        case .night:       return "Night"
        case .unspecified: return "Anytime"
        }
    }

    var symbol: String {
        switch self {
        case .morning:     return "sunrise.fill"
        case .afternoon:   return "sun.max.fill"
        case .evening:     return "sunset.fill"
        case .night:       return "moon.stars.fill"
        case .unspecified: return "clock"
        }
    }

    /// A sensible tag inferred from the hour of day, used when logging quickly.
    static func from(date: Date, calendar: Calendar = .current) -> TimeTag {
        switch calendar.component(.hour, from: date) {
        case 5..<12:  return .morning
        case 12..<17: return .afternoon
        case 17..<22: return .evening
        default:      return .night
        }
    }
}

/// Which arm a blood-pressure reading was taken on (BP only).
enum Arm: String, CaseIterable, Identifiable, Codable {
    case left, right, unspecified

    var id: String { rawValue }

    var label: String {
        switch self {
        case .left:        return "Left arm"
        case .right:       return "Right arm"
        case .unspecified: return "Not noted"
        }
    }

    var shortLabel: String {
        switch self {
        case .left:        return "L"
        case .right:       return "R"
        case .unspecified: return "—"
        }
    }
}
