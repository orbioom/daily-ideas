import Foundation

/// Saves the in-progress game to Application Support so a relaunch resumes it.
enum GameStore {
    private static var fileURL: URL? {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let folder = dir.appendingPathComponent("Palace", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("current-game.json")
    }

    static func save(_ state: GameState) {
        guard let url = fileURL else { return }
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: url, options: .atomic)
        } catch {
            // A failed save only costs resume-on-relaunch; never crash for it.
        }
    }

    static func load() -> GameState? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(GameState.self, from: data)
    }

    static func clear() {
        guard let url = fileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
