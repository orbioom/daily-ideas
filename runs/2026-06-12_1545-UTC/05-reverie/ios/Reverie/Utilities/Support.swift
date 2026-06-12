import Foundation
import UserNotifications

enum Fmt {
    static func date(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: d)
    }
    static func relativeDay(_ d: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(d) { return "Today" }
        if cal.isDateInYesterday(d) { return "Yesterday" }
        let f = DateFormatter(); f.dateFormat = "EEEE, MMM d"; return f.string(from: d)
    }
    static func monthYear(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f.string(from: d)
    }
}

/// Schedules gentle "reality check" reminders through the day, a core lucid
/// dreaming habit. Uses local notifications only — nothing leaves the device.
enum ReminderScheduler {
    private static let idPrefix = "reverie.realitycheck."
    private static let prompts = [
        "Are you dreaming? Look at your hands.",
        "Reality check: try to push a finger through your palm.",
        "Is this a dream? Read some text twice.",
        "Pause. Question reality. Are you awake?",
        "Reality check — pinch your nose and try to breathe."
    ]

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Reschedule `count` evenly-spaced reminders between `startHour` and `endHour`.
    static func reschedule(count: Int, startHour: Int, endHour: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: (0..<12).map { "\(idPrefix)\($0)" })
        guard count > 0, endHour > startHour else { return }
        let granted = await requestAuthorization()
        guard granted else { return }

        let span = endHour - startHour
        for i in 0..<count {
            let fraction = count == 1 ? 0.5 : Double(i) / Double(max(count - 1, 1))
            let totalMinutes = Double(startHour * 60) + fraction * Double(span * 60)
            var comps = DateComponents()
            comps.hour = Int(totalMinutes) / 60
            comps.minute = Int(totalMinutes) % 60

            let content = UNMutableNotificationContent()
            content.title = "Reality Check"
            content.body = prompts[i % prompts.count]
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let request = UNNotificationRequest(identifier: "\(idPrefix)\(i)", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: (0..<12).map { "\(idPrefix)\($0)" })
    }
}

/// Static educational content — lucid dreaming techniques.
struct TechniqueGuide: Identifiable {
    let id = UUID()
    let name: String
    let abbreviation: String
    let symbol: String
    let summary: String
    let steps: [String]
}

enum TechniqueLibrary {
    static let all: [TechniqueGuide] = [
        .init(name: "Reality Checks", abbreviation: "RC", symbol: "hand.raised.fingers.spread.fill",
              summary: "Habitually question whether you're dreaming so the habit carries into your dreams.",
              steps: [
                "Several times a day, ask yourself: \"Am I dreaming?\"",
                "Do a test: push a finger into your palm, read text twice, or pinch your nose and try to breathe.",
                "Notice your surroundings carefully — in dreams details shift.",
                "Pair checks with your personal dream signs for best results."
              ]),
        .init(name: "Mnemonic Induction", abbreviation: "MILD", symbol: "brain.head.profile",
              summary: "Use intention and memory to recognize you're dreaming.",
              steps: [
                "As you fall asleep, repeat: \"Next time I'm dreaming, I'll remember I'm dreaming.\"",
                "Visualize becoming lucid in a recent dream.",
                "Hold the intention as you drift off.",
                "Best combined with WBTB after ~5 hours of sleep."
              ]),
        .init(name: "Wake Back to Bed", abbreviation: "WBTB", symbol: "bed.double.fill",
              summary: "Wake during peak REM, then return to sleep with lucid intent.",
              steps: [
                "Sleep for about 5 hours, then wake with an alarm.",
                "Stay up 15–30 minutes — read about lucid dreaming or journal.",
                "Return to bed and apply MILD or WILD.",
                "Keep the lights low to stay sleepy."
              ]),
        .init(name: "Wake-Initiated", abbreviation: "WILD", symbol: "eye.fill",
              summary: "Pass directly from waking into a dream while staying aware.",
              steps: [
                "Lie still and relax completely after WBTB.",
                "Let your body fall asleep while your mind stays gently awake.",
                "Observe hypnagogic imagery without grabbing at it.",
                "Enter the forming dream scene calmly when it stabilizes."
              ]),
        .init(name: "Dream Journaling", abbreviation: "Recall", symbol: "book.closed.fill",
              summary: "The foundation: better recall means more dreams to become lucid in.",
              steps: [
                "Keep Reverie by your bed and log dreams the moment you wake.",
                "Capture feelings and fragments even if the plot is fuzzy.",
                "Review entries to spot your recurring dream signs.",
                "Set the intention to remember as you fall asleep."
              ])
    ]
}
