import Foundation

/// Metronome note subdivision. Each click subdivides the beat by `clicksPerBeat`.
enum Subdivision: Int, CaseIterable, Identifiable, Codable {
    case quarter = 1
    case eighth = 2
    case triplet = 3
    case sixteenth = 4

    var id: Int { rawValue }

    /// How many clicks per beat this subdivision produces.
    var clicksPerBeat: Int { rawValue }

    var label: String {
        switch self {
        case .quarter:   return "Quarter"
        case .eighth:    return "Eighth"
        case .triplet:   return "Triplet"
        case .sixteenth: return "Sixteenth"
        }
    }

    var symbol: String {
        switch self {
        case .quarter:   return "♩"
        case .eighth:    return "♫"
        case .triplet:   return "♪³"
        case .sixteenth: return "♬"
        }
    }

    /// Pro-only subdivisions (free tier gets quarter + eighth).
    var requiresPro: Bool {
        switch self {
        case .quarter, .eighth: return false
        case .triplet, .sixteenth: return true
        }
    }
}

/// A time signature. Top = beats per measure, bottom = note value.
struct TimeSignature: Equatable, Identifiable, Hashable {
    let top: Int
    let bottom: Int

    var id: String { "\(top)/\(bottom)" }
    var label: String { "\(top)/\(bottom)" }

    /// Common (free) meters vs. odd (Pro) meters.
    static let common: [TimeSignature] = [
        TimeSignature(top: 2, bottom: 4),
        TimeSignature(top: 3, bottom: 4),
        TimeSignature(top: 4, bottom: 4)
    ]

    static let odd: [TimeSignature] = [
        TimeSignature(top: 6, bottom: 8),
        TimeSignature(top: 5, bottom: 4),
        TimeSignature(top: 7, bottom: 8),
        TimeSignature(top: 9, bottom: 8),
        TimeSignature(top: 12, bottom: 8)
    ]

    static var all: [TimeSignature] { common + odd }

    var requiresPro: Bool { !TimeSignature.common.contains(self) }
}

/// Click timbre options, persisted as a raw string.
enum ClickStyle: String, CaseIterable, Identifiable, Codable {
    case classic = "Classic"
    case wood = "Wood Block"
    case soft = "Soft"

    var id: String { rawValue }

    /// Base frequency (Hz) of the non-accented click for this style.
    var baseFrequency: Double {
        switch self {
        case .classic: return 1000
        case .wood:    return 1800
        case .soft:    return 700
        }
    }

    /// Exponential decay time-constant (seconds) — controls click "tightness".
    var decay: Double {
        switch self {
        case .classic: return 0.04
        case .wood:    return 0.02
        case .soft:    return 0.08
        }
    }
}
