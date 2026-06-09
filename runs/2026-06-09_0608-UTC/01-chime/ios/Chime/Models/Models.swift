import Foundation
import SwiftData

/// A bell tone used to mark the start, interval points, and end of a sit.
/// Each tone maps to a synthesized fundamental + harmonics in `BellPlayer`.
enum BellTone: String, CaseIterable, Identifiable, Codable {
    case none, bowl, gong, chime, woodblock, temple

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return "Silent"
        case .bowl: return "Singing bowl"
        case .gong: return "Gong"
        case .chime: return "Chime"
        case .woodblock: return "Woodblock"
        case .temple: return "Temple bell"
        }
    }

    var symbol: String {
        switch self {
        case .none: return "speaker.slash"
        case .bowl: return "circle.circle"
        case .gong: return "circle.hexagongrid"
        case .chime: return "bell"
        case .woodblock: return "square.stack.3d.up"
        case .temple: return "building.columns"
        }
    }

    /// Fundamental frequency in Hz used by the synthesizer.
    var frequency: Double {
        switch self {
        case .none: return 0
        case .bowl: return 320
        case .gong: return 110
        case .chime: return 660
        case .woodblock: return 880
        case .temple: return 256
        }
    }

    /// Decay time in seconds — longer for resonant bells.
    var decay: Double {
        switch self {
        case .none: return 0
        case .bowl: return 4.5
        case .gong: return 5.5
        case .chime: return 2.5
        case .woodblock: return 0.5
        case .temple: return 4.0
        }
    }
}

/// A reusable meditation configuration: a warm-up, a duration, and optional
/// interval bells. Built-in presets seed on first launch; users add their own.
@Model
final class MeditationPreset {
    var name: String
    var minutes: Int            // meditation length (excludes warm-up)
    var warmupSeconds: Int      // settling time before the first bell
    var intervalMinutes: Int    // 0 = no interval bells
    var startBellRaw: String
    var intervalBellRaw: String
    var endBellRaw: String
    var isBuiltIn: Bool
    var sortIndex: Int
    var createdAt: Date

    init(name: String,
         minutes: Int,
         warmupSeconds: Int = 10,
         intervalMinutes: Int = 0,
         startBell: BellTone = .bowl,
         intervalBell: BellTone = .chime,
         endBell: BellTone = .bowl,
         isBuiltIn: Bool = false,
         sortIndex: Int = 0) {
        self.name = name
        self.minutes = min(max(minutes, 1), 240)
        self.warmupSeconds = min(max(warmupSeconds, 0), 120)
        self.intervalMinutes = min(max(intervalMinutes, 0), 120)
        self.startBellRaw = startBell.rawValue
        self.intervalBellRaw = intervalBell.rawValue
        self.endBellRaw = endBell.rawValue
        self.isBuiltIn = isBuiltIn
        self.sortIndex = sortIndex
        self.createdAt = .now
    }

    var startBell: BellTone {
        get { BellTone(rawValue: startBellRaw) ?? .bowl }
        set { startBellRaw = newValue.rawValue }
    }
    var intervalBell: BellTone {
        get { BellTone(rawValue: intervalBellRaw) ?? .chime }
        set { intervalBellRaw = newValue.rawValue }
    }
    var endBell: BellTone {
        get { BellTone(rawValue: endBellRaw) ?? .bowl }
        set { endBellRaw = newValue.rawValue }
    }

    var totalSeconds: Int { warmupSeconds + minutes * 60 }

    /// Offsets (seconds from the end of warm-up) at which an interval bell rings.
    var intervalOffsets: [Int] {
        guard intervalMinutes > 0 else { return [] }
        let step = intervalMinutes * 60
        guard step < minutes * 60 else { return [] }
        var out: [Int] = []
        var t = step
        while t < minutes * 60 {
            out.append(t)
            t += step
        }
        return out
    }

    var subtitle: String {
        var parts = ["\(minutes) min"]
        if warmupSeconds > 0 { parts.append("\(warmupSeconds)s settle") }
        if intervalMinutes > 0 { parts.append("bell every \(intervalMinutes) min") }
        return parts.joined(separator: " · ")
    }
}

/// A logged sit. `actualSeconds` may be less than planned if ended early.
@Model
final class MeditationSession {
    var date: Date
    var presetName: String
    var plannedSeconds: Int
    var actualSeconds: Int
    var completed: Bool
    var feeling: Int    // 0 = unrated, 1…5
    var note: String

    init(date: Date = .now,
         presetName: String,
         plannedSeconds: Int,
         actualSeconds: Int,
         completed: Bool,
         feeling: Int = 0,
         note: String = "") {
        self.date = date
        self.presetName = presetName
        self.plannedSeconds = max(0, plannedSeconds)
        self.actualSeconds = max(0, actualSeconds)
        self.completed = completed
        self.feeling = min(max(feeling, 0), 5)
        self.note = note
    }

    var minutes: Int { Int((Double(actualSeconds) / 60).rounded()) }
}
