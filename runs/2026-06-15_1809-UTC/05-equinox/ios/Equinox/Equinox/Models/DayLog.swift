import Foundation
import SwiftData

/// Menstrual / withdrawal flow. Perimenopausal cycles are irregular, so this is a free
/// daily marker rather than a strict cycle model.
enum Flow: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case spotting = "Spotting"
    case light = "Light"
    case medium = "Medium"
    case heavy = "Heavy"

    var id: String { rawValue }

    /// Ordinal intensity (0 = none). Anything ≥ spotting counts as a "period day" for cycle math.
    var intensity: Int {
        switch self {
        case .none: return 0
        case .spotting: return 1
        case .light: return 2
        case .medium: return 3
        case .heavy: return 4
        }
    }

    var isBleeding: Bool { intensity >= Flow.spotting.intensity }

    var symbol: String {
        switch self {
        case .none: return "circle"
        case .spotting: return "drop"
        case .light: return "drop.fill"
        case .medium: return "drop.fill"
        case .heavy: return "drop.triangle.fill"
        }
    }
}

/// One day's check-in. Exactly one `DayLog` exists per calendar day (keyed by `date`,
/// normalized to the start of day). Severity and treatment collections are stored as
/// JSON `Data` and encoded/decoded safely — never with `try!` or force-unwrap.
@Model
final class DayLog {
    /// Stable identity for SwiftUI lists.
    var id: UUID = UUID()
    /// Start-of-day for the logged date. Treated as unique per day by app logic.
    var date: Date = Date()

    var hotFlashCount: Int = 0
    var nightSweats: Bool = false

    /// 1–5 self-ratings (3 = neutral). 0 is treated as "not set" by the UI but stored as 3 by default.
    var mood: Int = 3
    var sleepQuality: Int = 3
    var energy: Int = 3

    var flowRaw: String = Flow.none.rawValue

    /// JSON-encoded `[String: Int]` — symptom key → severity 0–3.
    var symptomsData: Data = Data()
    /// JSON-encoded `[String]` — treatment / supplement names taken today.
    var treatmentsData: Data = Data()

    var notes: String = ""

    init(date: Date,
         hotFlashCount: Int = 0,
         nightSweats: Bool = false,
         mood: Int = 3,
         sleepQuality: Int = 3,
         energy: Int = 3,
         flow: Flow = .none,
         symptoms: [String: Int] = [:],
         treatments: [String] = [],
         notes: String = "") {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.hotFlashCount = max(0, hotFlashCount)
        self.nightSweats = nightSweats
        self.mood = Self.clampRating(mood)
        self.sleepQuality = Self.clampRating(sleepQuality)
        self.energy = Self.clampRating(energy)
        self.flowRaw = flow.rawValue
        self.notes = notes
        self.symptomsData = Self.encodeSymptoms(symptoms)
        self.treatmentsData = Self.encodeTreatments(treatments)
    }

    // MARK: - Derived accessors (safe)

    var flow: Flow {
        get { Flow(rawValue: flowRaw) ?? .none }
        set { flowRaw = newValue.rawValue }
    }

    /// Decoded symptom severities, filtered to known keys and valid 0–3 range.
    var symptoms: [String: Int] {
        get { Self.decodeSymptoms(symptomsData) }
        set { symptomsData = Self.encodeSymptoms(newValue) }
    }

    var treatments: [String] {
        get { Self.decodeTreatments(treatmentsData) }
        set { treatmentsData = Self.encodeTreatments(newValue) }
    }

    func severity(for key: String) -> Int {
        symptoms[key] ?? 0
    }

    /// True if anything meaningful was recorded — used for streaks and empty checks.
    var hasContent: Bool {
        hotFlashCount > 0
            || nightSweats
            || flow.isBleeding
            || !symptoms.isEmpty
            || !treatments.isEmpty
            || !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || mood != 3 || sleepQuality != 3 || energy != 3
    }

    // MARK: - Static helpers

    static func clampRating(_ value: Int) -> Int { min(5, max(1, value)) }

    static func encodeSymptoms(_ dict: [String: Int]) -> Data {
        // Drop zero/none entries and clamp severities defensively.
        var clean: [String: Int] = [:]
        for (k, v) in dict where v > 0 {
            clean[k] = min(3, max(0, v))
        }
        return (try? JSONEncoder().encode(clean)) ?? Data()
    }

    static func decodeSymptoms(_ data: Data) -> [String: Int] {
        guard !data.isEmpty,
              let raw = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        var clean: [String: Int] = [:]
        for (k, v) in raw where v > 0 {
            clean[k] = min(3, max(0, v))
        }
        return clean
    }

    static func encodeTreatments(_ list: [String]) -> Data {
        let clean = Array(Set(list)).sorted()
        return (try? JSONEncoder().encode(clean)) ?? Data()
    }

    static func decodeTreatments(_ data: Data) -> [String] {
        guard !data.isEmpty,
              let raw = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return raw
    }
}
