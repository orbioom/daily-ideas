import UIKit
import AudioToolbox

/// Purposeful, sparse feedback — gated by the Settings toggle. Never on every tap.
/// Uses haptics plus optional system sounds; no bundled audio assets (so nothing can
/// be missing at runtime). System sounds respect the device silent switch automatically.
enum Haptics {
    static func success(enabled: Bool) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning(enabled: Bool) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func impact(enabled: Bool, style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    /// A short, heavier transition cue used when a run moves to the next segment.
    static func transition(enabled: Bool) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    /// A light count-in tick (final lead-in seconds).
    static func tick(enabled: Bool) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7)
    }
}

/// Optional audible cues backed only by built-in system sounds (no bundled files).
enum Cue {
    /// A short, neutral system tick for count-in seconds.
    static func tick(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(1104) // Tock
    }

    /// A brighter system sound at a segment transition.
    static func transition(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(1113) // Begin Record (short, neutral chime)
    }

    /// A completion sound when the whole routine finishes.
    static func complete(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(1025) // Fanfare-style short complete
    }
}

/// Formatting helpers for durations shown across the app.
enum DurationFormat {
    /// "0:40", "1:05", "12:00". Always at least M:SS.
    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let minutes = s / 60
        let secs = s % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    /// "40s", "1m 5s", "12m". Friendly compact form for cards and summaries.
    static func compact(_ seconds: Int) -> String {
        let s = max(0, seconds)
        if s < 60 { return "\(s)s" }
        let minutes = s / 60
        let secs = s % 60
        if secs == 0 { return "\(minutes)m" }
        return "\(minutes)m \(secs)s"
    }
}
