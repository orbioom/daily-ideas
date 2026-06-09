import Foundation
import SwiftData

/// A single logged vital. One model covers every metric; `kind` decides which
/// fields are meaningful. Blood pressure uses `systolic`/`diastolic`/`pulse`;
/// every other metric uses `value` (always stored in canonical units — kg for
/// weight, mg/dL for glucose, % for SpO₂, bpm for pulse).
@Model
final class VitalEntry {
    var date: Date
    var kindRaw: String
    var systolic: Int        // BP only
    var diastolic: Int       // BP only
    var pulse: Int           // BP optional (0 = not recorded)
    var value: Double        // weight / glucose / spo2 / pulse-only
    var tagRaw: String
    var armRaw: String       // BP only
    var note: String

    init(date: Date = .now,
         kind: VitalKind,
         systolic: Int = 0,
         diastolic: Int = 0,
         pulse: Int = 0,
         value: Double = 0,
         tag: TimeTag = .unspecified,
         arm: Arm = .unspecified,
         note: String = "") {
        self.date = date
        self.kindRaw = kind.rawValue
        self.systolic = min(max(systolic, 0), 260)
        self.diastolic = min(max(diastolic, 0), 180)
        self.pulse = min(max(pulse, 0), 250)
        self.value = max(0, value)
        self.tagRaw = tag.rawValue
        self.armRaw = arm.rawValue
        self.note = note
    }

    // MARK: - Computed enum getters/setters

    var kind: VitalKind {
        get { VitalKind(rawValue: kindRaw) ?? .bloodPressure }
        set { kindRaw = newValue.rawValue }
    }

    var tag: TimeTag {
        get { TimeTag(rawValue: tagRaw) ?? .unspecified }
        set { tagRaw = newValue.rawValue }
    }

    var arm: Arm {
        get { Arm(rawValue: armRaw) ?? .unspecified }
        set { armRaw = newValue.rawValue }
    }

    // MARK: - BP derived metrics

    /// Mean arterial pressure: diastolic + (systolic − diastolic) / 3.
    var meanArterialPressure: Int {
        guard systolic >= diastolic, diastolic > 0 else { return 0 }
        return diastolic + (systolic - diastolic) / 3
    }

    /// Pulse pressure: systolic − diastolic.
    var pulsePressure: Int {
        max(0, systolic - diastolic)
    }

    /// The AHA category for this reading (BP only).
    var category: BPCategory {
        BPClassifier.classify(systolic: systolic, diastolic: diastolic)
    }

    /// Clamps incoming fields to safe ranges. Used by the editor on save so the
    /// model never holds nonsense even if the picker is misused.
    func clampAll() {
        systolic = min(max(systolic, 0), 260)
        diastolic = min(max(diastolic, 0), 180)
        pulse = min(max(pulse, 0), 250)
        value = max(0, value)
    }
}
