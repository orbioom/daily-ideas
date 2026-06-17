import Foundation

/// Static description of a built-in measurement site, used for seeding and as a
/// fallback for display metadata.
struct SiteSpec {
    let key: String
    let name: String
    let kind: UnitKind
    let symbol: String
}

enum SiteCatalog {
    /// The 14 built-in sites, in canonical display order.
    static let builtIn: [SiteSpec] = [
        SiteSpec(key: "weight", name: "Weight", kind: .mass, symbol: "scalemass"),
        SiteSpec(key: "bodyfat", name: "Body fat %", kind: .percent, symbol: "drop.halffull"),
        SiteSpec(key: "neck", name: "Neck", kind: .length, symbol: "person.bust"),
        SiteSpec(key: "shoulders", name: "Shoulders", kind: .length, symbol: "figure.arms.open"),
        SiteSpec(key: "chest", name: "Chest", kind: .length, symbol: "lungs"),
        SiteSpec(key: "waist", name: "Waist", kind: .length, symbol: "circle.dashed"),
        SiteSpec(key: "hips", name: "Hips", kind: .length, symbol: "figure.stand"),
        SiteSpec(key: "bicepL", name: "Left Bicep", kind: .length, symbol: "figure.strengthtraining.functional"),
        SiteSpec(key: "bicepR", name: "Right Bicep", kind: .length, symbol: "figure.strengthtraining.functional"),
        SiteSpec(key: "thighL", name: "Left Thigh", kind: .length, symbol: "figure.walk"),
        SiteSpec(key: "thighR", name: "Right Thigh", kind: .length, symbol: "figure.walk"),
        SiteSpec(key: "calfL", name: "Left Calf", kind: .length, symbol: "shoeprints.fill"),
        SiteSpec(key: "calfR", name: "Right Calf", kind: .length, symbol: "shoeprints.fill"),
        SiteSpec(key: "forearm", name: "Forearm", kind: .length, symbol: "hand.raised")
    ]

    static func spec(for key: String) -> SiteSpec? {
        builtIn.first { $0.key == key }
    }

    static func symbol(for key: String) -> String {
        spec(for: key)?.symbol ?? "ruler"
    }
}
