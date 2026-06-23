import Foundation
import SwiftData

/// Singleton-style settings record persisted via SwiftData.
@Model
final class AppSettings {
    var hapticsEnabled: Bool
    var defaultTravelerCount: Int
    /// Multiplier applied to clothing quantities (laundry habits): 0=light,1=normal,2=generous.
    var packingStyleRaw: Int
    /// Reminder lead time in days before departure (informational preference).
    var reminderLeadDays: Int
    var measurementMetric: Bool
    var createdAt: Date

    init(
        hapticsEnabled: Bool = true,
        defaultTravelerCount: Int = 1,
        packingStyle: PackingStyle = .normal,
        reminderLeadDays: Int = 3,
        measurementMetric: Bool = true,
        createdAt: Date = .now
    ) {
        self.hapticsEnabled = hapticsEnabled
        self.defaultTravelerCount = max(1, defaultTravelerCount)
        self.packingStyleRaw = packingStyle.rawValue
        self.reminderLeadDays = reminderLeadDays
        self.measurementMetric = measurementMetric
        self.createdAt = createdAt
    }

    var packingStyle: PackingStyle {
        get { PackingStyle(rawValue: packingStyleRaw) ?? .normal }
        set { packingStyleRaw = newValue.rawValue }
    }
}

/// How generously clothing scales with trip length.
enum PackingStyle: Int, CaseIterable, Identifiable {
    case light = 0
    case normal = 1
    case generous = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .light: return "Light"
        case .normal: return "Balanced"
        case .generous: return "Generous"
        }
    }

    var detail: String {
        switch self {
        case .light: return "Pack minimal, plan to do laundry"
        case .normal: return "A fresh set most days"
        case .generous: return "Plenty of spares, no laundry"
        }
    }

    /// Multiplier applied to per-night clothing counts.
    var multiplier: Double {
        switch self {
        case .light: return 0.7
        case .normal: return 1.0
        case .generous: return 1.3
        }
    }
}
