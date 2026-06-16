import Foundation
import SwiftData

/// Seeds sample profiles + a few weeks of journal entries so the wheel, placements,
/// compatibility, and Today history populate convincingly.
///
/// Birth data below is PUBLIC and widely documented (Wikipedia / Astro-Databank
/// "AA"-rated where noted). It is used purely to demonstrate the engine.
enum SeedData {

    /// Build a UTC `Date` from local birth components + the location's UTC offset (hours).
    static func utc(year: Int, month: Int, day: Int, hour: Int, minute: Int, offset: Double) -> Date {
        var cal = Calendar(identifier: .gregorian)
        if let utc = TimeZone(identifier: "UTC") { cal.timeZone = utc }
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        comps.hour = hour; comps.minute = minute
        let localAsUTC = cal.date(from: comps) ?? Date(timeIntervalSince1970: 0)
        // Local time minus offset = UTC. (e.g. 09:00 at -5 → 14:00 UTC.)
        return localAsUTC.addingTimeInterval(-offset * 3600)
    }

    private struct Sample {
        let name: String
        let y: Int; let mo: Int; let d: Int; let h: Int; let mi: Int
        let hasTime: Bool
        let cityID: String
        let seed: Int
    }

    private static let samples: [Sample] = [
        // Documented public birth times (Astro-Databank Rodden rating AA where noted).
        Sample(name: "Albert Einstein", y: 1879, mo: 3, d: 14, h: 11, mi: 30, hasTime: true, cityID: "munich", seed: 0),
        Sample(name: "Frida Kahlo", y: 1907, mo: 7, d: 6, h: 8, mi: 30, hasTime: true, cityID: "mexicocity", seed: 1),
        Sample(name: "Martin Luther King Jr.", y: 1929, mo: 1, d: 15, h: 12, mi: 0, hasTime: true, cityID: "atlanta", seed: 2),
        Sample(name: "Marie Curie", y: 1867, mo: 11, d: 7, h: 12, mi: 0, hasTime: false, cityID: "warsaw", seed: 3),
        // Generic example people so couples/compatibility feel relatable.
        Sample(name: "Maya R.", y: 1994, mo: 6, d: 21, h: 7, mi: 15, hasTime: true, cityID: "newyork", seed: 4),
        Sample(name: "Theo L.", y: 1991, mo: 11, d: 2, h: 22, mi: 40, hasTime: true, cityID: "london", seed: 5),
        Sample(name: "Aisha N.", y: 1998, mo: 2, d: 14, h: 16, mi: 5, hasTime: true, cityID: "dubai", seed: 6)
    ]

    static func hasData(in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<Profile>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count > 0
    }

    /// Insert samples (idempotent — only seeds when no profiles exist). Returns the
    /// id of the profile to make primary, if any.
    @discardableResult
    static func seedIfEmpty(context: ModelContext) -> UUID? {
        guard !hasData(in: context) else { return nil }
        return seed(context: context)
    }

    /// Force a fresh seed (used by Settings "Load sample data").
    @discardableResult
    static func seed(context: ModelContext) -> UUID? {
        var firstID: UUID?
        var primary: Profile?

        for (idx, s) in samples.enumerated() {
            let city = CityGazetteer.city(id: s.cityID) ?? CityGazetteer.cities[0]
            let birthUTC = utc(year: s.y, month: s.mo, day: s.d, hour: s.h, minute: s.mi, offset: city.tzOffset)
            let profile = Profile(name: s.name,
                                  birthDate: birthUTC,
                                  hasExactTime: s.hasTime,
                                  latitude: city.latitude,
                                  longitude: city.longitude,
                                  locationName: city.displayName,
                                  tzOffsetHours: city.tzOffset,
                                  isPrimary: idx == 4,   // Maya R. as the demo "you"
                                  colorSeed: s.seed)
            context.insert(profile)
            if firstID == nil { firstID = profile.id }
            if profile.isPrimary { primary = profile }
        }

        // Seed ~20 journal entries over the past weeks for the streak + Today history.
        seedJournal(context: context, for: primary)

        try? context.save()
        return primary?.id ?? firstID
    }

    private static func seedJournal(context: ModelContext, for profile: Profile?) {
        let cal = Calendar.current
        let notes = [
            "Quiet morning, slow coffee. Felt clear-headed.",
            "A hard conversation that ended well.",
            "Tired but proud of finishing the project.",
            "Restless — too much in my head today.",
            "Long walk, good music, calm evening.",
            "Reconnected with an old friend.",
            "Focused and productive, time flew.",
            "Felt off, couldn't say why. Rested early.",
            "Small win at work. Celebrated quietly.",
            "Open and curious — said yes to something new.",
            "Homebody day. Cooked, read, recharged.",
            "Emotional but in a soft, useful way.",
            "Energized by a new idea.",
            "Needed solitude and took it.",
            "Grateful, plainly grateful."
        ]
        let moods = [3, 4, 3, 2, 5, 4, 4, 2, 4, 5, 3, 3, 5, 3, 5, 4, 2, 4, 3, 5]
        let name = profile?.name ?? "You"

        let natal = profile.map { ChartService.chart(for: $0) }

        for offset in 1...20 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let mood = moods[(offset - 1) % moods.count]
            let note = notes[(offset - 1) % notes.count]
            var transitSummary = ""
            if let natal {
                let reading = TransitEngine.reading(natal: natal, on: day, baseOrb: 6, includeOutlook: false)
                transitSummary = reading.strongest?.headline ?? "Moon in \(reading.moonSign.name)"
            }
            let entry = JournalEntry(date: day,
                                     mood: mood,
                                     note: note,
                                     transitSummary: transitSummary,
                                     profileName: name)
            context.insert(entry)
        }
    }
}
