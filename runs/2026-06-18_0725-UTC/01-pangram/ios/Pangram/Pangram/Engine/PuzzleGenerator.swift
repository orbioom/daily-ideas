import Foundation

/// Builds `Puzzle` values from seeds. Deterministic for a date key (so the Daily is identical
/// for everyone that day) and random for Practice.
enum PuzzleGenerator {

    /// The Daily puzzle for a given date key. Same seed for everyone on that date.
    static func daily(for dateKey: String) -> Puzzle {
        var rng = SplitMix64(seed: SeedKey.hash("daily-" + dateKey))
        let index = rng.index(below: WordData.seeds.count)
        return build(seedIndex: index, dateKey: dateKey, isDaily: true, idPrefix: "daily")
    }

    /// A fresh random practice puzzle. The id includes a salt so repeated taps differ.
    static func practice(salt: UInt64) -> Puzzle {
        var rng = SplitMix64(seed: SeedKey.hash("practice") ^ salt)
        let index = rng.index(below: WordData.seeds.count)
        let key = DateKey.today
        return build(seedIndex: index, dateKey: key, isDaily: false, idPrefix: "practice-\(salt)")
    }

    /// Rebuild a puzzle from a persisted SavedPuzzle (resume path).
    static func rebuild(from saved: SavedPuzzle) -> Puzzle {
        let safeIndex = WordData.seeds.indices.contains(saved.seedIndex) ? saved.seedIndex : 0
        return build(
            seedIndex: safeIndex,
            dateKey: saved.dateKey,
            isDaily: saved.isDaily,
            idPrefix: saved.isDaily ? "daily" : "practice-resume"
        )
    }

    /// Core builder: resolves a seed into a full puzzle, computing the solution set from the dictionary.
    static func build(seedIndex: Int, dateKey: String, isDaily: Bool, idPrefix: String) -> Puzzle {
        let safeIndex = WordData.seeds.indices.contains(seedIndex) ? seedIndex : 0
        let seed = WordData.seeds[safeIndex]
        let center = seed.center.first ?? "a"
        let outer = seed.outer.compactMap { $0.first }
        let letterSet = seed.letterSet

        var solutions: [String] = []
        var pangrams: [String] = []
        var totalScore = 0

        for word in WordData.words where word.count >= 4 {
            guard word.contains(center) else { continue }
            if Set(word).isSubset(of: letterSet) {
                let isP = Scoring.isPangram(word, letterSet: letterSet)
                solutions.append(word)
                if isP { pangrams.append(word) }
                totalScore += Scoring.points(for: word, isPangram: isP)
            }
        }

        solutions.sort()
        pangrams.sort()

        let id = isDaily ? "daily-\(dateKey)" : "\(idPrefix)"
        return Puzzle(
            id: id,
            dateKey: dateKey,
            isDaily: isDaily,
            seedIndex: safeIndex,
            center: center,
            outer: outer,
            solutions: solutions,
            pangrams: pangrams,
            totalPossibleScore: totalScore
        )
    }
}
