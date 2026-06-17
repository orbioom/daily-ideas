import Foundation
import SwiftData

/// Reads and writes GlyphProgress for a profile. Keeps SwiftData mutations in
/// one place so views stay declarative.
@MainActor
enum ProgressService {

    /// Fetch all progress rows for a profile.
    static func progress(for profileID: UUID, context: ModelContext) -> [GlyphProgress] {
        let predicate = #Predicate<GlyphProgress> { $0.profileID == profileID }
        let descriptor = FetchDescriptor<GlyphProgress>(predicate: predicate)
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Best stars earned for one glyph by a profile (0 if never attempted).
    static func bestStars(profileID: UUID, glyphKey: String, context: ModelContext) -> Int {
        var descriptor = FetchDescriptor<GlyphProgress>(
            predicate: #Predicate { $0.profileID == profileID && $0.glyphKey == glyphKey }
        )
        descriptor.fetchLimit = 1
        let rows = (try? context.fetch(descriptor)) ?? []
        return rows.first?.bestStars ?? 0
    }

    /// Record an attempt; updates best stars and bumps counters. Returns whether
    /// this attempt set a new personal best.
    @discardableResult
    static func record(
        profileID: UUID,
        glyphKey: String,
        stars: Int,
        context: ModelContext
    ) -> Bool {
        let clampedStars = max(0, min(3, stars))
        var descriptor = FetchDescriptor<GlyphProgress>(
            predicate: #Predicate { $0.profileID == profileID && $0.glyphKey == glyphKey }
        )
        descriptor.fetchLimit = 1
        let rows = (try? context.fetch(descriptor)) ?? []

        if let row = rows.first {
            row.attempts += 1
            row.lastPracticed = .now
            let isBest = clampedStars > row.bestStars
            if isBest { row.bestStars = clampedStars }
            try? context.save()
            return isBest
        } else {
            let row = GlyphProgress(
                profileID: profileID,
                glyphKey: glyphKey,
                bestStars: clampedStars,
                attempts: 1,
                lastPracticed: .now
            )
            context.insert(row)
            try? context.save()
            return clampedStars > 0
        }
    }

    /// Aggregate stats used by the Progress screen.
    struct Stats {
        var totalStars: Int = 0
        var masteredCount: Int = 0          // glyphs at 3 stars
        var attemptedCount: Int = 0
        var starsPerSet: [GlyphSetKind: Int] = [:]
        var masteredPerSet: [GlyphSetKind: Int] = [:]
    }

    static func stats(for profileID: UUID, context: ModelContext) -> Stats {
        let rows = progress(for: profileID, context: context)
        var stats = Stats()
        for row in rows {
            stats.totalStars += row.bestStars
            stats.attemptedCount += 1
            if row.bestStars >= 3 { stats.masteredCount += 1 }
            if let setKind = setKind(forKey: row.glyphKey) {
                stats.starsPerSet[setKind, default: 0] += row.bestStars
                if row.bestStars >= 3 {
                    stats.masteredPerSet[setKind, default: 0] += 1
                }
            }
        }
        return stats
    }

    /// Most recent attempts, newest first.
    static func recent(for profileID: UUID, limit: Int, context: ModelContext) -> [GlyphProgress] {
        progress(for: profileID, context: context)
            .sorted { $0.lastPracticed > $1.lastPracticed }
            .prefix(limit)
            .map { $0 }
    }

    /// Derive the set kind from a glyph key prefix ("U_", "L_", "N_", "S_").
    static func setKind(forKey key: String) -> GlyphSetKind? {
        guard let prefix = key.split(separator: "_").first else { return nil }
        return GlyphSetKind(rawValue: String(prefix))
    }
}
