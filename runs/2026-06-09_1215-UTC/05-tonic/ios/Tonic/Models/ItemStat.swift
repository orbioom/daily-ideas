import Foundation
import SwiftData

/// Per-item mastery: how often a single Interval / ChordType / ScaleType has been
/// seen and how often it was answered correctly. One row per practiced item.
/// `key` is a stable identifier like "interval.P5" or "chord.minor".
@Model
final class ItemStat {
    @Attribute(.unique) var key: String
    var attempts: Int
    var correct: Int
    var lastSeen: Date

    init(key: String, attempts: Int = 0, correct: Int = 0, lastSeen: Date = .now) {
        self.key = key
        self.attempts = max(0, attempts)
        self.correct = min(max(0, correct), max(0, attempts))
        self.lastSeen = lastSeen
    }

    /// Fraction correct, 0…1. Guards divide-by-zero.
    var accuracy: Double {
        guard attempts > 0 else { return 0 }
        return Double(correct) / Double(attempts)
    }

    // MARK: - Key helpers

    /// Build the stable key for an item of a given drill type.
    static func key(type: DrillType, itemRaw: String) -> String {
        "\(type.keyPrefix).\(itemRaw)"
    }

    /// The drill type encoded in a key, if recognizable.
    var drillType: DrillType? {
        guard let prefix = key.split(separator: ".").first else { return nil }
        return DrillType(rawValue: String(prefix))
    }

    /// A human label for this item, derived from its key.
    var displayLabel: String {
        let parts = key.split(separator: ".", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return key }
        let raw = parts[1]
        switch DrillType(rawValue: parts[0]) {
        case .interval: return Interval(rawValue: raw)?.label ?? raw
        case .chord: return ChordType(rawValue: raw)?.label ?? raw
        case .scale: return ScaleType(rawValue: raw)?.label ?? raw
        case .none: return raw
        }
    }
}
