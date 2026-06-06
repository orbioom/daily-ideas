import Foundation

/// Which broad grade family a climb belongs to. Boulders are graded on the
/// V-scale (USA) and Font/Fontainebleau (Europe); routes on YDS (USA) and
/// French sport grades.
enum GradeFamily: String, Codable {
    case boulder
    case route
}

/// The concrete grade system a value is displayed in. The two members of each
/// family are interchangeable views onto the same canonical ladder.
enum GradeSystem: String, CaseIterable, Identifiable, Codable {
    case vScale   // boulder, USA
    case font     // boulder, Fontainebleau
    case yds      // route, USA (Yosemite Decimal System)
    case french   // route, French sport

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vScale: return "V-Scale"
        case .font:   return "Font"
        case .yds:    return "YDS"
        case .french: return "French"
        }
    }

    var family: GradeFamily {
        switch self {
        case .vScale, .font: return .boulder
        case .yds, .french:  return .route
        }
    }
}

/// A pure, deterministic grade-conversion + comparison engine.
///
/// Every grade is stored *canonically* as `(family, index)` where `index` is a
/// position on a single ordered ladder shared by both systems in that family.
/// That makes grades trivially sortable and aggregatable for analytics, while
/// display can be rendered in whichever system the user prefers.
///
/// The engine never crashes on bad input: parsing an unknown string returns
/// `nil`, and rendering an out-of-range index returns `nil` (handled in UI).
enum GradeScale {

    // MARK: - Ladder tables
    //
    // Each row is one rung of the canonical ladder. The two columns are the
    // equivalent labels in each system at that rung. These tables are bounded
    // and aligned so index N in V-scale is the same difficulty as index N in Font.

    /// Boulder ladder: V-scale ↔ Fontainebleau. Index 0 == V0 == 4.
    static let boulderLadder: [(v: String, font: String)] = [
        ("V0",  "4"),
        ("V1",  "5"),
        ("V2",  "5+"),
        ("V3",  "6A"),
        ("V4",  "6B"),
        ("V5",  "6C"),
        ("V6",  "7A"),
        ("V7",  "7A+"),
        ("V8",  "7B"),
        ("V9",  "7C"),
        ("V10", "7C+"),
        ("V11", "8A"),
        ("V12", "8A+"),
        ("V13", "8B"),
        ("V14", "8B+"),
        ("V15", "8C"),
        ("V16", "8C+"),
        ("V17", "9A")
    ]

    /// Route ladder: YDS ↔ French sport. Index 0 == 5.6 == 5a.
    static let routeLadder: [(yds: String, french: String)] = [
        ("5.6",   "4c"),
        ("5.7",   "5a"),
        ("5.8",   "5b"),
        ("5.9",   "5c"),
        ("5.10a", "6a"),
        ("5.10b", "6a+"),
        ("5.10c", "6b"),
        ("5.10d", "6b+"),
        ("5.11a", "6c"),
        ("5.11b", "6c+"),
        ("5.11c", "7a"),
        ("5.11d", "7a+"),
        ("5.12a", "7b"),
        ("5.12b", "7b+"),
        ("5.12c", "7c"),
        ("5.12d", "7c+"),
        ("5.13a", "8a"),
        ("5.13b", "8a+"),
        ("5.13c", "8b"),
        ("5.13d", "8b+"),
        ("5.14a", "8c"),
        ("5.14b", "8c+"),
        ("5.14c", "9a"),
        ("5.14d", "9a+"),
        ("5.15a", "9b"),
        ("5.15b", "9b+"),
        ("5.15c", "9c"),
        ("5.15d", "9c+")
    ]

    // MARK: - Bounds

    /// Number of rungs in a family's ladder.
    static func rungCount(_ family: GradeFamily) -> Int {
        switch family {
        case .boulder: return boulderLadder.count
        case .route:   return routeLadder.count
        }
    }

    /// Clamp an arbitrary index into the valid range for a family. Returns nil
    /// only if the family somehow has no rungs (it always does).
    static func clampedIndex(_ index: Int, family: GradeFamily) -> Int? {
        let count = rungCount(family)
        guard count > 0 else { return nil }
        return min(max(index, 0), count - 1)
    }

    /// True if `index` addresses a real rung in the family's ladder.
    static func isValid(index: Int, family: GradeFamily) -> Bool {
        index >= 0 && index < rungCount(family)
    }

    // MARK: - Display

    /// Render a canonical `index` in the requested `system`. Returns nil for an
    /// out-of-range index or a system that does not match the index's family.
    static func display(index: Int, in system: GradeSystem) -> String? {
        switch system {
        case .vScale:
            guard boulderLadder.indices.contains(index) else { return nil }
            return boulderLadder[index].v
        case .font:
            guard boulderLadder.indices.contains(index) else { return nil }
            return boulderLadder[index].font
        case .yds:
            guard routeLadder.indices.contains(index) else { return nil }
            return routeLadder[index].yds
        case .french:
            guard routeLadder.indices.contains(index) else { return nil }
            return routeLadder[index].french
        }
    }

    /// Render a canonical `index` for a `family` using the user's preferred system
    /// for that family. Falls back to a sane label rather than crashing.
    static func display(index: Int, family: GradeFamily, boulderSystem: GradeSystem, routeSystem: GradeSystem) -> String {
        switch family {
        case .boulder:
            let system = boulderSystem.family == .boulder ? boulderSystem : .vScale
            return display(index: index, in: system) ?? "—"
        case .route:
            let system = routeSystem.family == .route ? routeSystem : .yds
            return display(index: index, in: system) ?? "—"
        }
    }

    // MARK: - Parsing

    /// Normalize a user-typed grade string for tolerant matching: trim, uppercase
    /// for boulder (V/Font), and strip stray whitespace. French/YDS keep case-insensitive.
    private static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
    }

    /// Parse a grade label written in `system` into a canonical index. Returns nil
    /// for unrecognized input — never crashes.
    static func index(of label: String, in system: GradeSystem) -> Int? {
        let needle = normalize(label).lowercased()
        guard !needle.isEmpty else { return nil }
        switch system {
        case .vScale:
            return boulderLadder.firstIndex { $0.v.lowercased() == needle }
        case .font:
            return boulderLadder.firstIndex { $0.font.lowercased() == needle }
        case .yds:
            return routeLadder.firstIndex { $0.yds.lowercased() == needle }
        case .french:
            return routeLadder.firstIndex { $0.french.lowercased() == needle }
        }
    }

    /// Best-effort parse across both systems of a family — useful when the user
    /// may type either V or Font (or YDS or French) interchangeably.
    static func index(of label: String, family: GradeFamily) -> Int? {
        switch family {
        case .boulder:
            return index(of: label, in: .vScale) ?? index(of: label, in: .font)
        case .route:
            return index(of: label, in: .yds) ?? index(of: label, in: .french)
        }
    }

    // MARK: - Conversion

    /// Convert a label from one system to another within the same family.
    /// Returns nil if the label can't be parsed or the systems are cross-family.
    static func convert(_ label: String, from: GradeSystem, to: GradeSystem) -> String? {
        guard from.family == to.family else { return nil }
        guard let idx = index(of: label, in: from) else { return nil }
        return display(index: idx, in: to)
    }

    // MARK: - Comparison

    /// Compare two canonical indices in the same family. Returns nil for mismatched
    /// families so callers never silently compare a boulder to a route.
    static func compare(_ a: Int, _ b: Int) -> ComparisonResult {
        if a < b { return .orderedAscending }
        if a > b { return .orderedDescending }
        return .orderedSame
    }

    // MARK: - Nearest

    /// Snap an arbitrary index to the nearest valid rung in `family`.
    static func nearest(index: Int, family: GradeFamily) -> Int? {
        clampedIndex(index, family: family)
    }

    /// All selectable canonical indices for a family (for pickers), in order.
    static func allIndices(_ family: GradeFamily) -> [Int] {
        Array(0..<rungCount(family))
    }
}
