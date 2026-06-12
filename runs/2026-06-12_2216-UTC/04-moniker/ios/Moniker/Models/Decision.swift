import Foundation
import SwiftData

enum Partner: String, CaseIterable, Codable, Identifiable {
    case a, b

    var id: String { rawValue }
}

/// One partner's verdict on one name. The pair (nameID, partner) is unique
/// by construction — the engine replaces rather than duplicates.
@Model
final class Decision {
    var nameID: String
    var partnerRaw: String
    var liked: Bool
    var date: Date

    init(nameID: String, partner: Partner, liked: Bool, date: Date = .now) {
        self.nameID = nameID
        self.partnerRaw = partner.rawValue
        self.liked = liked
        self.date = date
    }

    var partner: Partner { Partner(rawValue: partnerRaw) ?? .a }
}

/// Pure functions over the decision set.
enum MatchEngine {
    static func decisions(for partner: Partner, in all: [Decision]) -> [Decision] {
        all.filter { $0.partnerRaw == partner.rawValue }
    }

    static func likedIDs(for partner: Partner, in all: [Decision]) -> Set<String> {
        Set(all.filter { $0.partnerRaw == partner.rawValue && $0.liked }.map(\.nameID))
    }

    static func decidedIDs(for partner: Partner, in all: [Decision]) -> Set<String> {
        Set(all.filter { $0.partnerRaw == partner.rawValue }.map(\.nameID))
    }

    /// Names both partners liked, newest mutual like first.
    static func matches(in all: [Decision]) -> [NameEntry] {
        let likedA = likedIDs(for: .a, in: all)
        let likedB = likedIDs(for: .b, in: all)
        let mutual = likedA.intersection(likedB)
        let latestDate: [String: Date] = all.reduce(into: [:]) { dict, decision in
            guard mutual.contains(decision.nameID) else { return }
            dict[decision.nameID] = max(dict[decision.nameID] ?? .distantPast, decision.date)
        }
        return mutual
            .compactMap { NameCatalog.entry(id: $0) }
            .sorted { (latestDate[$0.id] ?? .distantPast) > (latestDate[$1.id] ?? .distantPast) }
    }

    /// Of all names partner A liked, the share partner B also liked (and vice
    /// versa) — a light "taste agreement" signal for the insights screen.
    static func agreementRate(in all: [Decision]) -> Double? {
        let likedA = likedIDs(for: .a, in: all)
        let likedB = likedIDs(for: .b, in: all)
        let decidedA = decidedIDs(for: .a, in: all)
        let decidedB = decidedIDs(for: .b, in: all)
        // Only count names both have actually seen.
        let bothDecided = decidedA.intersection(decidedB)
        guard !bothDecided.isEmpty else { return nil }
        let agreed = bothDecided.filter { likedA.contains($0) == likedB.contains($0) }
        return Double(agreed.count) / Double(bothDecided.count)
    }

    /// Deterministic deck order shared by both partners, seeded per household.
    static func deck(
        gender: NameGender?,
        styles: Set<NameStyle>,
        excluding decided: Set<String>,
        seed: UInt64
    ) -> [NameEntry] {
        var pool = NameCatalog.all
        if let gender {
            pool = pool.filter { $0.gender == gender }
        }
        if !styles.isEmpty {
            pool = pool.filter { !styles.isDisjoint(with: $0.styles) }
        }
        // SplitMix64-seeded Fisher–Yates: both partners get the same order.
        var rng = SplitMix64(seed: seed)
        var shuffled = pool
        if shuffled.count > 1 {
            for i in (1..<shuffled.count).reversed() {
                let j = Int(rng.next() % UInt64(i + 1))
                shuffled.swapAt(i, j)
            }
        }
        return shuffled.filter { !decided.contains($0.id) }
    }
}

struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
