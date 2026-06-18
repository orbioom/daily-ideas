import Foundation

/// USDA-safe minimum internal temperatures plus preferred (chef) doneness targets.
enum DonenessEngine {

    struct DonenessGuide: Identifiable, Hashable {
        let id: String
        let food: String
        /// USDA minimum safe internal temperature, °F.
        let safeF: Int
        /// Preferred / recommended target for best results, °F (may equal safe).
        let preferredF: Int
        let note: String

        var safeC: Int { Self.toC(safeF) }
        var preferredC: Int { Self.toC(preferredF) }

        static func toC(_ f: Int) -> Int {
            Int((Double(f) - 32) * 5 / 9 + (f >= 0 ? 0.5 : -0.5))
        }
    }

    /// The full doneness reference table.
    static let guides: [DonenessGuide] = [
        DonenessGuide(id: "poultry", food: "Chicken & Turkey", safeF: 165, preferredF: 165,
                      note: "Whole, ground, and pieces. Measure the thickest part, away from bone."),
        DonenessGuide(id: "chicken-thigh", food: "Chicken Thighs (dark)", safeF: 165, preferredF: 175,
                      note: "Safe at 165°F, but 175°F renders connective tissue for a better texture."),
        DonenessGuide(id: "beef-steak", food: "Beef Steak — Medium-Rare", safeF: 145, preferredF: 130,
                      note: "USDA safe is 145°F + 3 min rest. Many prefer 130–135°F for medium-rare."),
        DonenessGuide(id: "beef-medium", food: "Beef Steak — Medium", safeF: 145, preferredF: 145,
                      note: "Firm but still juicy. Rest 3 minutes before slicing."),
        DonenessGuide(id: "ground-beef", food: "Ground Beef & Burgers", safeF: 160, preferredF: 160,
                      note: "Ground meat must reach 160°F — no pink-center exception."),
        DonenessGuide(id: "pork", food: "Pork Chops & Roasts", safeF: 145, preferredF: 145,
                      note: "145°F + 3 min rest. A blush of pink is safe and juicy."),
        DonenessGuide(id: "ground-pork", food: "Ground Pork & Sausage", safeF: 160, preferredF: 160,
                      note: "Cook ground pork through to 160°F."),
        DonenessGuide(id: "fish", food: "Fish & Seafood", safeF: 145, preferredF: 145,
                      note: "Flesh turns opaque and flakes. Salmon can be pulled at 125–130°F if you prefer it medium."),
        DonenessGuide(id: "shrimp", food: "Shrimp & Shellfish", safeF: 145, preferredF: 145,
                      note: "Cook until opaque and firm; shrimp curl into a loose C, not a tight O."),
        DonenessGuide(id: "lamb", food: "Lamb (chops/roast)", safeF: 145, preferredF: 140,
                      note: "145°F + 3 min rest for safe; 140°F gives a rosy medium."),
        DonenessGuide(id: "leftovers", food: "Leftovers & Reheats", safeF: 165, preferredF: 165,
                      note: "Reheat all leftovers to 165°F throughout, stirring where you can."),
        DonenessGuide(id: "eggs", food: "Egg Dishes", safeF: 160, preferredF: 160,
                      note: "Cook until both yolk and white are firm; casseroles to 160°F."),
    ]

    static func guide(id: String) -> DonenessGuide? {
        guides.first { $0.id == id }
    }
}
