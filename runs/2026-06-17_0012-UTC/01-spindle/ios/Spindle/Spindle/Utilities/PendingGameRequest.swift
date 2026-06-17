import Foundation

/// A tiny hand-off between the "New" tab and the live Play screen. The New tab
/// stores the chosen mode + deal kind; PlayView consumes it on appear and starts
/// the game with its own view-model. Backed by UserDefaults so it survives the
/// tab switch without a shared object graph.
enum PendingGameRequest {
    private static let modeKey = "pendingGameMode"
    private static let kindKey = "pendingGameKind"

    /// Stores a pending request. `kind` is encoded as JSON.
    static func set(mode: SuitMode, kind: DealKind) {
        let defaults = UserDefaults.standard
        defaults.set(mode.rawValue, forKey: modeKey)
        if let data = try? JSONEncoder().encode(kind) {
            defaults.set(data, forKey: kindKey)
        }
    }

    /// Consumes and clears any pending request.
    static func take() -> (SuitMode, DealKind)? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: modeKey) != nil else { return nil }
        let rawMode = defaults.integer(forKey: modeKey)
        let mode = SuitMode(rawValue: rawMode) ?? .one
        let kind: DealKind
        if let data = defaults.data(forKey: kindKey),
           let decoded = try? JSONDecoder().decode(DealKind.self, from: data) {
            kind = decoded
        } else {
            kind = .random
        }
        defaults.removeObject(forKey: modeKey)
        defaults.removeObject(forKey: kindKey)
        return (mode, kind)
    }

    static func clear() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: modeKey)
        defaults.removeObject(forKey: kindKey)
    }
}
