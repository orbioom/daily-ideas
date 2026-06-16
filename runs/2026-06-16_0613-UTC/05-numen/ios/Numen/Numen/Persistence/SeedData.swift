import Foundation
import SwiftData

/// Seeds a few public-domain example profiles on first run so the app is alive
/// immediately, and sets the initially selected profile.
enum SeedData {

    private struct Sample {
        let fullName: String
        let nickname: String
        let year: Int, month: Int, day: Int
    }

    /// Public-domain historical figures with well-documented birthdates.
    private static let samples: [Sample] = [
        Sample(fullName: "Albert Einstein", nickname: "Albert", year: 1879, month: 3, day: 14),
        Sample(fullName: "Ada Lovelace", nickname: "Ada", year: 1815, month: 12, day: 10),
        Sample(fullName: "Leonardo da Vinci", nickname: "Leonardo", year: 1452, month: 4, day: 15)
    ]

    @MainActor
    static func seedIfNeeded(_ context: ModelContext, settings: AppSettings) {
        let descriptor = FetchDescriptor<Profile>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else {
            ensureSelection(context, settings: settings)
            return
        }

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current

        for sample in samples {
            var comps = DateComponents()
            comps.year = sample.year
            comps.month = sample.month
            comps.day = sample.day
            comps.hour = 12
            let date = cal.date(from: comps) ?? Date(timeIntervalSince1970: 0)
            let profile = Profile(fullName: sample.fullName, birthdate: date, nickname: sample.nickname)
            context.insert(profile)
        }
        try? context.save()
        ensureSelection(context, settings: settings)
    }

    /// Make sure the @AppStorage selected id points at an existing profile.
    @MainActor
    static func ensureSelection(_ context: ModelContext, settings: AppSettings) {
        let descriptor = FetchDescriptor<Profile>(sortBy: [SortDescriptor(\.createdAt)])
        let profiles = (try? context.fetch(descriptor)) ?? []
        guard !profiles.isEmpty else {
            settings.selectedProfileID = ""
            return
        }
        let current = settings.selectedProfileID
        let stillValid = profiles.contains { $0.persistentModelID.storageIdentifier == current }
        if current.isEmpty || !stillValid {
            settings.selectedProfileID = profiles[0].persistentModelID.storageIdentifier
        }
    }
}

extension PersistentIdentifier {
    /// A stable string key for @AppStorage selection tracking.
    var storageIdentifier: String { String(describing: self) }
}
