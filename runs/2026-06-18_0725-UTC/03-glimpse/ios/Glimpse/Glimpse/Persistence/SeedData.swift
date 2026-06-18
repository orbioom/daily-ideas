import Foundation
import SwiftData

/// Seeds realistic sample moments on first launch, each with a generated
/// gradient+grain JPEG in the ImageStore. Guarded by a UserDefaults flag so it
/// runs exactly once.
@MainActor
enum SeedData {
    private static let seededKey = "didSeedMoments_v1"

    private static let captions: [String] = [
        "Morning light across the kitchen table.",
        "Found this little café down a side street.",
        "Rain all afternoon — stayed in with tea.",
        "The park was gold today. Couldn't stop looking up.",
        "Quiet walk before everyone else woke up.",
        "Cooked something new and it actually worked.",
        "Long call with an old friend. Worth every minute.",
        "City felt softer than usual at dusk.",
        "Books, blanket, nowhere to be.",
        "First proper sun in weeks.",
        "Lost track of time at the market.",
        "Small win at work — let myself feel it.",
        "The dog refused to leave this patch of light.",
        "Sketched a little. Badly. Happily.",
        "Walked the long way home on purpose.",
        "Everything smelled like rain and cut grass.",
        "A whole evening with no plans.",
        "Caught the last of the sunset from the roof.",
        "Made coffee just to hold the warm cup.",
        "The hills were doing that hazy blue thing.",
        "Reorganised the shelf. Oddly satisfying.",
        "Train window scenery on the way out of town.",
        "Stayed up too late talking. No regrets.",
        "Tiny flowers pushing through the pavement.",
        "Slow start, gentle day.",
        "Music on, windows open, floor swept.",
        "The good kind of tired tonight.",
        "Wrote a page that finally felt right.",
        "Steam off the tea, frost on the glass.",
        "Watched the storm roll in from far off."
    ]

    private static let tagPool: [[String]] = [
        ["home", "calm"],
        ["coffee", "city"],
        ["rain", "cozy"],
        ["park", "outdoors"],
        ["morning", "quiet"],
        ["cooking", "win"],
        ["friends"],
        ["sunset", "city"],
        ["reading"],
        ["sun", "outdoors"],
        ["market"],
        ["work", "win"],
        ["dog", "home"],
        ["creative"],
        ["walk", "outdoors"],
        ["nature"],
        ["rest"],
        ["roof", "sunset"],
        ["coffee", "calm"],
        ["travel"]
    ]

    private static let titles: [String] = [
        "", "", "", // many days have no title
        "Slow Sunday", "First sun", "Side street", "Golden hour",
        "Small win", "Long way home", "Storm watching", "Quiet morning"
    ]

    static func seedIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: seededKey) else { return }

        // Extra guard: if any moments already exist, don't double-seed.
        let existing = (try? context.fetch(FetchDescriptor<Moment>())) ?? []
        guard existing.isEmpty else {
            defaults.set(true, forKey: seededKey)
            return
        }

        var rng = SeededRandom(seed: 0xC0FFEE)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var created = 0
        let targetCount = 40
        var dayOffset = 0
        // Walk back day by day over ~8 weeks, logging most days (skip a few to
        // create realistic gaps), until we have ~40 moments.
        while created < targetCount && dayOffset < 60 {
            dayOffset += 1
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            // Skip roughly 1 in 6 days to leave gaps in the streak/calendar.
            if rng.nextUnit() < 0.16 { continue }

            let seed = created &* 31 &+ dayOffset
            let image = SeedArtwork.make(seed: seed)
            let filename = ImageStore.shared.save(image, maxDimension: 1200, quality: 0.8)

            let caption = captions[rng.nextInt(in: 0..<captions.count)]
            let tags = tagPool[rng.nextInt(in: 0..<tagPool.count)]
            let title = titles[rng.nextInt(in: 0..<titles.count)]
            // Mood skewed slightly positive.
            let moodRoll = rng.nextUnit()
            let mood: Mood
            switch moodRoll {
            case ..<0.10: mood = .rough
            case ..<0.25: mood = .low
            case ..<0.45: mood = .neutral
            case ..<0.78: mood = .good
            default: mood = .great
            }

            // A scattering of favorites.
            let favorite = rng.nextUnit() < 0.18

            // createdAt: give it a plausible time of day.
            let hour = rng.nextInt(in: 7..<22)
            let minute = rng.nextInt(in: 0..<60)
            let createdAt = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day

            let moment = Moment(
                dayKey: DayKey.key(for: day),
                createdAt: createdAt,
                title: title,
                caption: caption,
                mood: mood,
                imageFilename: filename,
                tags: tags,
                isFavorite: favorite
            )
            context.insert(moment)
            created += 1
        }

        try? context.save()
        defaults.set(true, forKey: seededKey)
    }
}
