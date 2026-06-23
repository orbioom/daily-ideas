import Foundation
import SwiftData

/// Convenience accessor that fetches (or creates) the single AppSettings row.
@MainActor
enum SettingsStore {
    static func current(in context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        if let existing = try? context.fetch(descriptor), let first = existing.first {
            return first
        }
        let created = AppSettings()
        context.insert(created)
        try? context.save()
        return created
    }
}
