import Foundation
import SwiftData

/// What a drill trains: hearing intervals, identifying chord qualities, or scales.
enum DrillType: String, CaseIterable, Identifiable, Codable {
    case interval, chord, scale
    var id: String { rawValue }
    var label: String {
        switch self {
        case .interval: return "Intervals"
        case .chord: return "Chords"
        case .scale: return "Scales"
        }
    }
    var symbol: String {
        switch self {
        case .interval: return "arrow.up.arrow.down"
        case .chord: return "square.stack.3d.up"
        case .scale: return "pianokeys"
        }
    }
    /// Stable prefix for `ItemStat.key`, e.g. "interval.P5".
    var keyPrefix: String { rawValue }
}

/// How the notes of a question are sounded. `harmonic` (all at once) is only
/// meaningful for intervals and chords; scales always play melodically.
enum PlayDirection: String, CaseIterable, Identifiable, Codable {
    case ascending, descending, harmonic
    var id: String { rawValue }
    var label: String {
        switch self {
        case .ascending: return "Ascending"
        case .descending: return "Descending"
        case .harmonic: return "Harmonic"
        }
    }
}

/// Where the root note of each question comes from.
enum RootMode: String, CaseIterable, Identifiable, Codable {
    case fixedC, random
    var id: String { rawValue }
    var label: String {
        switch self {
        case .fixedC: return "Fixed (C)"
        case .random: return "Random root"
        }
    }
}

/// A reusable ear-training configuration: which items are in play, how they're
/// sounded, and from what root. Built-ins seed on first launch; users add their own.
@Model
final class Drill {
    var name: String
    var typeRaw: String
    var enabledKeys: [String]   // raw identifiers of enabled Interval / ChordType / ScaleType
    var directionRaw: String
    var rootModeRaw: String
    var isBuiltIn: Bool
    var sortIndex: Int
    var createdAt: Date

    init(name: String,
         type: DrillType,
         enabledKeys: [String],
         direction: PlayDirection = .ascending,
         rootMode: RootMode = .fixedC,
         isBuiltIn: Bool = false,
         sortIndex: Int = 0) {
        self.name = name
        self.typeRaw = type.rawValue
        // Guard against an empty configuration by falling back to a sensible default.
        self.enabledKeys = enabledKeys.isEmpty ? Drill.defaultKeys(for: type) : enabledKeys
        self.directionRaw = direction.rawValue
        self.rootModeRaw = rootMode.rawValue
        self.isBuiltIn = isBuiltIn
        self.sortIndex = sortIndex
        self.createdAt = .now
    }

    var type: DrillType {
        get { DrillType(rawValue: typeRaw) ?? .interval }
        set { typeRaw = newValue.rawValue }
    }
    var direction: PlayDirection {
        get { PlayDirection(rawValue: directionRaw) ?? .ascending }
        set { directionRaw = newValue.rawValue }
    }
    var rootMode: RootMode {
        get { RootMode(rawValue: rootModeRaw) ?? .fixedC }
        set { rootModeRaw = newValue.rawValue }
    }

    /// The play style this drill resolves to, honoring the type's constraints.
    var playStyle: PlayStyle {
        switch direction {
        case .ascending: return .sequenceAscending
        case .descending: return .sequenceDescending
        case .harmonic:
            // Scales can't truly be harmonic; fall back to ascending.
            return type == .scale ? .sequenceAscending : .simultaneous
        }
    }

    var subtitle: String {
        let count = enabledKeys.count
        let dir = type == .scale && direction == .harmonic ? PlayDirection.ascending.label : direction.label
        return "\(count) \(count == 1 ? "item" : "items") · \(dir) · \(rootMode.label)"
    }

    /// A reasonable default item set for each type (used as a validation fallback).
    static func defaultKeys(for type: DrillType) -> [String] {
        switch type {
        case .interval: return [Interval.P4, .P5, .M3, .m3].map(\.rawValue)
        case .chord: return [ChordType.major, .minor].map(\.rawValue)
        case .scale: return [ScaleType.major, .naturalMinor].map(\.rawValue)
        }
    }
}
