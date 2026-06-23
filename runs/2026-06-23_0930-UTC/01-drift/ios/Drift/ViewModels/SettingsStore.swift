import Foundation
import SwiftData

/// Convenience for fetching-or-creating the single SleepSettings record.
enum SettingsStore {
    @MainActor
    static func current(_ context: ModelContext) -> SleepSettings {
        let existing = (try? context.fetch(FetchDescriptor<SleepSettings>())) ?? []
        if let first = existing.first { return first }
        let created = SleepSettings()
        context.insert(created)
        try? context.save()
        return created
    }
}
