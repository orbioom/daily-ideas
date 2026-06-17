import Foundation

/// A serialisable snapshot of an in-progress run, persisted so a session can be
/// resumed exactly after backgrounding or a full relaunch.
struct ActiveRunSnapshot: Codable {
    var planId: String
    var sessionId: String
    var week: Int
    var sessionIndex: Int
    /// Wall-clock start of the current (running) segment.
    var startDate: Date
    /// Elapsed seconds accumulated before the current segment.
    var accumulated: TimeInterval
    var isPaused: Bool
}

/// Persists the active-run snapshot to UserDefaults as JSON. Tiny, transient
/// state — primary data still lives in SwiftData.
final class ActiveRunStore {
    private let key = "lace.activeRun"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(_ snapshot: ActiveRunSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    func load() -> ActiveRunSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ActiveRunSnapshot.self, from: data)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
