import Foundation

/// A line in the synastry breakdown.
struct CompatibilityRow: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let positive: Bool
}

/// The full synastry result for two profiles.
struct CompatibilityResult {
    let score: Int                 // 0...100
    let harmonious: Int
    let challenging: Int
    let aspects: [AspectHit]
    let rows: [CompatibilityRow]
    let summary: String
}

enum CompatibilityEngine {

    static func compare(_ a: Profile, _ b: Profile, baseOrb: Double) -> CompatibilityResult {
        let chartA = ChartService.chart(for: a)
        let chartB = ChartService.chart(for: b)

        let cross = AspectEngine.synastry(chartA.positions, chartB.positions, baseOrb: baseOrb)
        let harmonious = cross.filter { $0.kind.isHarmonious }.count
        let challenging = cross.filter { $0.kind.isChallenging }.count

        let score = scoreFrom(harmonious: harmonious, challenging: challenging, total: cross.count)

        var rows: [CompatibilityRow] = []

        // Big-three comparison rows.
        rows.append(elementRow(label: "Sun & Sun",
                               s1: chartA.position(.sun)?.sign, s2: chartB.position(.sun)?.sign,
                               aName: a.name, bName: b.name, kind: "core identities"))
        rows.append(elementRow(label: "Moon & Moon",
                               s1: chartA.position(.moon)?.sign, s2: chartB.position(.moon)?.sign,
                               aName: a.name, bName: b.name, kind: "emotional needs"))
        if let r1 = chartA.ascendantSign, let r2 = chartB.ascendantSign {
            rows.append(elementRow(label: "Rising & Rising",
                                   s1: r1, s2: r2,
                                   aName: a.name, bName: b.name, kind: "first impressions"))
        }

        // Notable cross-aspects (top 4 by tightness, luminaries first).
        let notable = cross
            .sorted { lhs, rhs in
                let lLum = lhs.a.isLuminary || lhs.b.isLuminary
                let rLum = rhs.a.isLuminary || rhs.b.isLuminary
                if lLum != rLum { return lLum }
                return lhs.orb < rhs.orb
            }
            .prefix(4)

        for hit in notable {
            rows.append(CompatibilityRow(
                title: "\(a.name)'s \(hit.a.name) \(hit.kind.rawValue.lowercased()) \(b.name)'s \(hit.b.name)",
                detail: hit.kind.meaning,
                positive: hit.kind.isHarmonious))
        }

        let summary = summaryText(score: score, harmonious: harmonious, challenging: challenging, a: a.name, b: b.name)

        return CompatibilityResult(score: score,
                                   harmonious: harmonious,
                                   challenging: challenging,
                                   aspects: cross,
                                   rows: rows,
                                   summary: summary)
    }

    private static func scoreFrom(harmonious: Int, challenging: Int, total: Int) -> Int {
        // Base 50, lifted by harmonious aspects, lowered by challenging ones, then
        // nudged by overall connection density. Guarded and clamped to 0...100.
        guard total > 0 else { return 50 }
        let net = Double(harmonious) - Double(challenging)
        let densityBonus = min(Double(total) * 1.5, 18)
        let raw = 50 + net * 4 + densityBonus
        return min(max(Int(raw.rounded()), 0), 100)
    }

    private static func elementRow(label: String, s1: ZodiacSign?, s2: ZodiacSign?,
                                   aName: String, bName: String, kind: String) -> CompatibilityRow {
        guard let s1, let s2 else {
            return CompatibilityRow(title: label, detail: "Not available without exact birth times.", positive: true)
        }
        let sameElement = s1.element == s2.element
        let compatibleElements = elementsHarmonize(s1.element, s2.element)
        let positive = sameElement || compatibleElements
        let detail: String
        if sameElement {
            detail = "Both \(s1.element.rawValue) — your \(kind) speak the same language naturally."
        } else if compatibleElements {
            detail = "\(s1.element.rawValue) and \(s2.element.rawValue) — different but complementary; your \(kind) can fuel each other."
        } else {
            detail = "\(s1.element.rawValue) meets \(s2.element.rawValue) — your \(kind) work differently, which asks for translation but offers real growth."
        }
        return CompatibilityRow(title: "\(label): \(s1.name) & \(s2.name)", detail: detail, positive: positive)
    }

    /// Fire+Air and Earth+Water are the classic complementary pairings.
    private static func elementsHarmonize(_ e1: Element, _ e2: Element) -> Bool {
        switch (e1, e2) {
        case (.fire, .air), (.air, .fire): return true
        case (.earth, .water), (.water, .earth): return true
        default: return false
        }
    }

    private static func summaryText(score: Int, harmonious: Int, challenging: Int, a: String, b: String) -> String {
        let band: String
        switch score {
        case 80...100: band = "a rare, easy resonance"
        case 65..<80: band = "strong, supportive chemistry"
        case 50..<65: band = "a balanced mix of ease and friction"
        case 35..<50: band = "real spark with real work to do"
        default: band = "a challenging pairing that rewards conscious effort"
        }
        return "\(a) and \(b) share \(band). \(harmonious) flowing and \(challenging) tense cross-aspects shape the connection — the tense ones aren't flaws, they're where the relationship grows."
    }
}
