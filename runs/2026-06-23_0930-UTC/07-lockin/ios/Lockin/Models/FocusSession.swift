import Foundation
import SwiftData

/// The kind of timer a session used.
enum SessionMode: String, Codable, CaseIterable, Identifiable {
    case pomodoro
    case custom
    case flow

    var id: String { rawValue }
    var label: String {
        switch self {
        case .pomodoro: return "Pomodoro"
        case .custom: return "Custom"
        case .flow: return "Flow"
        }
    }
    var symbol: String {
        switch self {
        case .pomodoro: return "timer"
        case .custom: return "slider.horizontal.3"
        case .flow: return "infinity"
        }
    }
}

/// A single completed (or abandoned) focus block.
@Model
final class FocusSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date
    /// Seconds the user actually spent focused (excludes paused time).
    var focusedSeconds: Int
    /// Planned length in seconds (0 for open-ended flow sessions).
    var plannedSeconds: Int
    var modeRaw: String
    var tag: String
    var note: String
    /// True when the user reached the planned target (always true for flow ≥ 1 min).
    var wasCompleted: Bool
    /// Number of times the user tapped the distraction counter.
    var distractionCount: Int

    var project: Project?

    init(id: UUID = UUID(),
         startedAt: Date,
         endedAt: Date,
         focusedSeconds: Int,
         plannedSeconds: Int,
         mode: SessionMode,
         tag: String = "",
         note: String = "",
         wasCompleted: Bool,
         distractionCount: Int = 0,
         project: Project? = nil) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.focusedSeconds = max(0, focusedSeconds)
        self.plannedSeconds = max(0, plannedSeconds)
        self.modeRaw = mode.rawValue
        self.tag = tag
        self.note = note
        self.wasCompleted = wasCompleted
        self.distractionCount = max(0, distractionCount)
        self.project = project
    }

    var mode: SessionMode { SessionMode(rawValue: modeRaw) ?? .custom }
    var focusedMinutes: Int { focusedSeconds / 60 }
    var hourOfDay: Int { Calendar.current.component(.hour, from: startedAt) }
}
