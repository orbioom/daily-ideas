import Foundation
import SwiftData

/// A single logged headache or migraine episode. `end == nil` means the attack
/// is still ongoing — the Today screen shows a live duration in that case.
@Model
final class Attack {
    var start: Date
    var end: Date?
    var intensity: Int          // 1…10
    var typeRaw: String
    var locationRaw: String
    var auraPresent: Bool
    var note: String
    var createdAt: Date

    // Many-to-many: a trigger / symptom can belong to many attacks.
    @Relationship var triggers: [Trigger]
    @Relationship var symptoms: [Symptom]
    // Meds are owned by the attack and removed with it.
    @Relationship(deleteRule: .cascade, inverse: \MedTaken.attack) var meds: [MedTaken]

    init(start: Date = .now,
         end: Date? = nil,
         intensity: Int = 5,
         type: HeadacheType = .migraine,
         location: HeadLocation = .unspecified,
         auraPresent: Bool = false,
         note: String = "",
         triggers: [Trigger] = [],
         symptoms: [Symptom] = []) {
        self.start = start
        self.end = end
        self.intensity = min(max(intensity, 1), 10)
        self.typeRaw = type.rawValue
        self.locationRaw = location.rawValue
        self.auraPresent = auraPresent
        self.note = note
        self.createdAt = .now
        self.triggers = triggers
        self.symptoms = symptoms
        self.meds = []
    }

    var type: HeadacheType {
        get { HeadacheType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    var location: HeadLocation {
        get { HeadLocation(rawValue: locationRaw) ?? .unspecified }
        set { locationRaw = newValue.rawValue }
    }

    var isOngoing: Bool { end == nil }

    /// Duration in whole minutes, or nil while the attack is still ongoing.
    var durationMinutes: Int? {
        guard let end else { return nil }
        return max(0, Int(end.timeIntervalSince(start) / 60))
    }
}
