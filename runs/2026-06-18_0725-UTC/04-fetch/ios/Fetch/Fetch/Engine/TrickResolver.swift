import Foundation

/// Resolves a trickId to a displayable `Trick`, checking the static catalog first,
/// then the supplied custom tricks. Always returns a safe fallback so the UI never
/// shows a broken reference.
enum TrickResolver {
    static func resolve(_ trickId: String, custom: [CustomTrick]) -> Trick {
        if let t = TrickCatalog.trick(trickId) { return t }
        if let c = custom.first(where: { $0.trickId == trickId }) { return c.asTrick }
        return Trick(
            id: trickId,
            name: "Unknown Trick",
            category: .tricks,
            difficulty: .easy,
            icon: "questionmark.circle",
            summary: "This trick is no longer available.",
            steps: [],
            tips: [],
            estimatedDays: 7,
            prerequisites: []
        )
    }

    /// Display name only (lighter lookup).
    static func name(_ trickId: String, custom: [CustomTrick]) -> String {
        TrickCatalog.trick(trickId)?.name
            ?? custom.first(where: { $0.trickId == trickId })?.name
            ?? "Unknown Trick"
    }

    static func icon(_ trickId: String, custom: [CustomTrick]) -> String {
        TrickCatalog.trick(trickId)?.icon
            ?? custom.first(where: { $0.trickId == trickId })?.icon
            ?? "pawprint.fill"
    }
}
