import Foundation
import SwiftData

/// One-time seeding of sample articles, tags, and highlights so every screen
/// is alive on first launch. Idempotent: keyed off a persisted flag.
@MainActor
enum Seeder {
    private static let didSeedKey = "didSeedSampleData"

    static func seedIfNeeded(context: ModelContext, wpm: Int) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: didSeedKey) else { return }

        // Build tags keyed by name (curated colors).
        var tagsByName: [String: Tag] = [:]
        let palette = TagPalette.hexes
        var colorIndex = 0
        func tag(named name: String) -> Tag {
            if let existing = tagsByName[name] { return existing }
            let hex = palette[colorIndex % palette.count]
            colorIndex += 1
            let t = Tag(name: name, colorHex: hex)
            tagsByName[name] = t
            context.insert(t)
            return t
        }

        let seeds = SampleArticles.seeds
        let articles = SampleArticles.all(wpm: wpm)

        for (article, seed) in zip(articles, seeds) {
            article.tags = seed.tagNames.map { tag(named: $0) }
            context.insert(article)
        }

        // A couple of seeded highlights so the Highlights collection is alive.
        if let slowWeb = articles.first(where: { $0.title.contains("Slower Web") }) {
            let h = Highlight(
                text: "Abundance without attention is just noise with a search bar.",
                article: slowWeb
            )
            context.insert(h)
        }
        if let walking = articles.first(where: { $0.title.contains("Walking") }) {
            let h = Highlight(
                text: "In wildness is the preservation of the world.",
                article: walking
            )
            context.insert(h)
        }

        do {
            try context.save()
            defaults.set(true, forKey: didSeedKey)
        } catch {
            // Non-fatal: if seeding fails we simply show empty states. The user
            // can still add their own articles. Never crash on a user path.
            context.rollback()
        }
    }
}
