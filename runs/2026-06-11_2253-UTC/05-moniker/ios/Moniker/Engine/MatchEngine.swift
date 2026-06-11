import Foundation

/// Pure matching + stats over verdicts. No UI, no I/O.
enum MatchEngine {

    struct Match: Identifiable {
        let card: NameCard
        /// 2 = both loved, 1 = one loved one liked, 0 = both liked.
        let heat: Int
        let matchedAt: Date
        var id: String { card.id }
    }

    /// Names both partners liked (or loved), hottest first then newest.
    static func matches(verdicts: [Verdict]) -> [Match] {
        let aLikes = positives(verdicts: verdicts, partner: .a)
        let bLikes = positives(verdicts: verdicts, partner: .b)
        var out: [Match] = []
        for (nameID, aVerdict) in aLikes {
            guard let bVerdict = bLikes[nameID],
                  let card = NameCatalog.card(forID: nameID) else { continue }
            let heat = (aVerdict.decision == .superlike ? 1 : 0) + (bVerdict.decision == .superlike ? 1 : 0)
            out.append(Match(card: card, heat: heat,
                             matchedAt: max(aVerdict.date, bVerdict.date)))
        }
        return out.sorted {
            $0.heat != $1.heat ? $0.heat > $1.heat : $0.matchedAt > $1.matchedAt
        }
    }

    private static func positives(verdicts: [Verdict], partner: Partner) -> [String: Verdict] {
        var map: [String: Verdict] = [:]
        for v in verdicts where v.partner == partner && v.decision != .pass {
            // Latest verdict wins if duplicates ever exist.
            if let existing = map[v.nameID], existing.date > v.date { continue }
            map[v.nameID] = v
        }
        return map
    }

    /// The most recent verdict per (name, partner).
    static func latestVerdict(verdicts: [Verdict], nameID: String, partner: Partner) -> Verdict? {
        verdicts
            .filter { $0.nameID == nameID && $0.partner == partner }
            .max { $0.date < $1.date }
    }

    /// Cards a partner hasn't decided yet, within a filtered pool.
    static func undecided(pool: [NameCard], verdicts: [Verdict], partner: Partner) -> [NameCard] {
        let decided = Set(verdicts.filter { $0.partner == partner }.map(\.nameID))
        return pool.filter { !decided.contains($0.id) }
    }

    struct Stats {
        let decidedA: Int
        let decidedB: Int
        let likedA: Int
        let likedB: Int
        let matchCount: Int
        /// Of names BOTH have decided, the share where they agree.
        let agreementRate: Double?
        let topStylesA: [(style: NameStyle, count: Int)]
        let topStylesB: [(style: NameStyle, count: Int)]
        let matchGenderCounts: [(gender: NameGender, count: Int)]
    }

    static func stats(verdicts: [Verdict]) -> Stats {
        let aAll = latestByName(verdicts: verdicts, partner: .a)
        let bAll = latestByName(verdicts: verdicts, partner: .b)
        let matchList = matches(verdicts: verdicts)

        var agreements = 0, overlap = 0
        for (nameID, av) in aAll {
            guard let bv = bAll[nameID] else { continue }
            overlap += 1
            let aPositive = av.decision != .pass
            let bPositive = bv.decision != .pass
            if aPositive == bPositive { agreements += 1 }
        }

        var genderCounts: [NameGender: Int] = [:]
        for m in matchList {
            genderCounts[m.card.gender, default: 0] += 1
        }

        return Stats(
            decidedA: aAll.count, decidedB: bAll.count,
            likedA: aAll.values.filter { $0.decision != .pass }.count,
            likedB: bAll.values.filter { $0.decision != .pass }.count,
            matchCount: matchList.count,
            agreementRate: overlap >= 5 ? Double(agreements) / Double(overlap) : nil,
            topStylesA: topStyles(of: aAll),
            topStylesB: topStyles(of: bAll),
            matchGenderCounts: genderCounts
                .map { (gender: $0.key, count: $0.value) }
                .sorted { $0.count > $1.count })
    }

    private static func latestByName(verdicts: [Verdict], partner: Partner) -> [String: Verdict] {
        var map: [String: Verdict] = [:]
        for v in verdicts where v.partner == partner {
            if let existing = map[v.nameID], existing.date > v.date { continue }
            map[v.nameID] = v
        }
        return map
    }

    private static func topStyles(of verdictsByName: [String: Verdict]) -> [(style: NameStyle, count: Int)] {
        var counts: [NameStyle: Int] = [:]
        for (nameID, v) in verdictsByName where v.decision != .pass {
            guard let card = NameCatalog.card(forID: nameID) else { continue }
            for style in card.styles {
                counts[style, default: 0] += v.decision == .superlike ? 2 : 1
            }
        }
        return counts.map { (style: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(3)
            .map { $0 }
    }

    /// Shareable text of the current top matches.
    static func shareText(matches: [Match], babyLastName: String) -> String {
        guard !matches.isEmpty else { return "No matched names yet." }
        var lines = ["Our baby-name shortlist 💛"]
        for (i, m) in matches.prefix(10).enumerated() {
            let suffix = babyLastName.isEmpty ? "" : " \(babyLastName)"
            let heart = m.heat == 2 ? "💖" : m.heat == 1 ? "💕" : "🤍"
            lines.append("\(i + 1). \(m.card.name)\(suffix) \(heart)")
        }
        return lines.joined(separator: "\n")
    }
}
