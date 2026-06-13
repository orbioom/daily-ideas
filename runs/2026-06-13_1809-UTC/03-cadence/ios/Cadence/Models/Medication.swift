import Foundation
import SwiftData

enum MedForm: String, Codable, CaseIterable, Identifiable {
    case tablet, capsule, liquid, drops, injection, inhaler, topical, supplement
    var id: String { rawValue }
    var label: String {
        switch self {
        case .tablet: return "Tablet"
        case .capsule: return "Capsule"
        case .liquid: return "Liquid"
        case .drops: return "Drops"
        case .injection: return "Injection"
        case .inhaler: return "Inhaler"
        case .topical: return "Topical"
        case .supplement: return "Supplement"
        }
    }
    var icon: String {
        switch self {
        case .tablet: return "pills.fill"
        case .capsule: return "capsule.fill"
        case .liquid: return "drop.fill"
        case .drops: return "eyedropper.halffull"
        case .injection: return "syringe.fill"
        case .inhaler: return "lungs.fill"
        case .topical: return "bandage.fill"
        case .supplement: return "leaf.fill"
        }
    }
    var doseNoun: String {
        switch self {
        case .liquid: return "dose"
        case .drops: return "drops"
        case .injection: return "shot"
        case .inhaler: return "puff"
        case .topical: return "application"
        default: return "unit"
        }
    }
}

enum ScheduleKind: String, Codable, CaseIterable, Identifiable {
    case everyDay, daysOfWeek, asNeeded
    var id: String { rawValue }
    var label: String {
        switch self {
        case .everyDay: return "Every day"
        case .daysOfWeek: return "Specific days"
        case .asNeeded: return "As needed"
        }
    }
}

@Model
final class Medication {
    var id: UUID
    var name: String
    var formRaw: String
    var strength: String          // free text, e.g. "500 mg"
    var colorHex: Int             // identity color (matches Theme.pillColors light value)
    var notes: String
    var scheduleRaw: String
    var dayMask: Int              // bit i (0=Sun … 6=Sat) for daysOfWeek schedules
    var times: [Int]             // minutes-of-day for scheduled doses
    var dosesPerTime: Int        // units taken at each scheduled time
    var supplyCount: Double      // units remaining on hand
    var refillThreshold: Double  // alert when supply at/below this
    var trackSupply: Bool
    var isActive: Bool
    var createdAt: Date

    init(name: String, form: MedForm, strength: String, colorHex: Int,
         schedule: ScheduleKind, dayMask: Int, times: [Int], dosesPerTime: Int,
         supplyCount: Double, refillThreshold: Double, trackSupply: Bool,
         notes: String = "") {
        self.id = UUID()
        self.name = name
        self.formRaw = form.rawValue
        self.strength = strength
        self.colorHex = colorHex
        self.notes = notes
        self.scheduleRaw = schedule.rawValue
        self.dayMask = dayMask
        self.times = times.sorted()
        self.dosesPerTime = max(1, dosesPerTime)
        self.supplyCount = max(0, supplyCount)
        self.refillThreshold = max(0, refillThreshold)
        self.trackSupply = trackSupply
        self.isActive = true
        self.createdAt = Date()
    }

    var form: MedForm {
        get { MedForm(rawValue: formRaw) ?? .tablet }
        set { formRaw = newValue.rawValue }
    }
    var schedule: ScheduleKind {
        get { ScheduleKind(rawValue: scheduleRaw) ?? .everyDay }
        set { scheduleRaw = newValue.rawValue }
    }

    /// Does this med's schedule include the given weekday (1=Sun … 7=Sat, Calendar style)?
    func occursOn(weekday: Int) -> Bool {
        switch schedule {
        case .everyDay: return true
        case .asNeeded: return false
        case .daysOfWeek:
            let bit = weekday - 1   // 0…6
            return (dayMask & (1 << bit)) != 0
        }
    }

    /// Total scheduled units per active day (for supply math).
    var unitsPerDay: Double {
        guard schedule != .asNeeded else { return 0 }
        return Double(times.count * dosesPerTime)
    }

    /// Estimated days of supply left, or nil if not tracked / no daily use.
    var daysOfSupply: Int? {
        guard trackSupply, unitsPerDay > 0 else { return nil }
        return Int((supplyCount / unitsPerDay).rounded(.down))
    }

    var needsRefill: Bool {
        trackSupply && supplyCount <= refillThreshold
    }
}
