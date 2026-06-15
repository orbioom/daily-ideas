import SwiftUI

/// What a tracker represents. Drives grouping, default colors, and which side of a
/// correlation it tends to sit on (factors predict, symptoms are outcomes).
enum TrackerKind: String, CaseIterable, Identifiable, Codable {
    case symptom
    case mood
    case factor
    case medication
    case measurement

    var id: String { rawValue }

    var title: String {
        switch self {
        case .symptom: return "Symptom"
        case .mood: return "Mood"
        case .factor: return "Factor"
        case .medication: return "Medication"
        case .measurement: return "Measurement"
        }
    }

    var plural: String {
        switch self {
        case .symptom: return "Symptoms"
        case .mood: return "Mood"
        case .factor: return "Factors"
        case .medication: return "Medications"
        case .measurement: return "Measurements"
        }
    }

    var symbol: String {
        switch self {
        case .symptom: return "bolt.heart"
        case .mood: return "face.smiling"
        case .factor: return "leaf"
        case .medication: return "pills"
        case .measurement: return "ruler"
        }
    }

    /// Whether this kind is usually an *outcome* (the thing you want to explain).
    var isOutcome: Bool {
        switch self {
        case .symptom, .mood: return true
        case .factor, .medication, .measurement: return false
        }
    }
}
