import Foundation

/// A recommended pull temperature for a given doneness level.
/// `chefLevel` entries are surfaced only to Pro (advanced doneness).
struct DonenessLevel: Identifiable, Hashable {
    let id = UUID()
    let name: String          // e.g. "Medium-rare", "USDA safe"
    let tempC: Double         // canonical Celsius pull temp
    let isUSDASafe: Bool      // marks the USDA-recommended safe minimum
    let chefLevel: Bool       // advanced (Pro) doneness level

    init(_ name: String, _ tempC: Double, usda: Bool = false, chef: Bool = false) {
        self.name = name
        self.tempC = tempC
        self.isUSDASafe = usda
        self.chefLevel = chef
    }
}

/// One cut in the doneness reference. Static catalog — never user-editable.
struct GuideEntry: Identifiable, Hashable {
    let id = UUID()
    let protein: Protein
    let cut: String
    let levels: [DonenessLevel]          // recommended pull temps by doneness
    let smokerTempC: Double              // recommended grill/smoker temp
    let minutesPerLb: Double             // approx cook time per pound
    let restMinutes: Int                 // recommended rest
    let woodPairing: String              // suggested wood
    let note: String                     // a useful tip

    /// The default target a new cook should use: the USDA-safe level if present,
    /// otherwise the middle listed level, otherwise the first.
    var defaultTargetC: Double {
        if let safe = levels.first(where: { $0.isUSDASafe }) { return safe.tempC }
        if let mid = levels[safe: levels.count / 2] { return mid.tempC }
        return levels.first?.tempC ?? 71
    }
}

/// The full live-fire doneness guide (>=30 cuts across beef/pork/poultry/fish/lamb/veg).
enum DonenessGuide {

    static let all: [GuideEntry] = beef + pork + poultry + fish + lamb + veg

    static func entries(for protein: Protein) -> [GuideEntry] {
        all.filter { $0.protein == protein }
    }

    static func cuts(for protein: Protein) -> [String] {
        entries(for: protein).map { $0.cut }
    }

    static func entry(protein: Protein, cut: String) -> GuideEntry? {
        all.first { $0.protein == protein && $0.cut == cut }
    }

    // MARK: Beef

    private static let beef: [GuideEntry] = [
        GuideEntry(protein: .beef, cut: "Ribeye Steak",
                   levels: [DonenessLevel("Rare", 52, chef: true),
                            DonenessLevel("Medium-rare", 57),
                            DonenessLevel("Medium", 63),
                            DonenessLevel("Medium-well", 68, chef: true),
                            DonenessLevel("Well done", 71)],
                   smokerTempC: 232, minutesPerLb: 8, restMinutes: 5,
                   woodPairing: "Oak or hickory",
                   note: "Sear hot and fast; pull 3°C below target for carryover."),
        GuideEntry(protein: .beef, cut: "Filet Mignon",
                   levels: [DonenessLevel("Rare", 52, chef: true),
                            DonenessLevel("Medium-rare", 57),
                            DonenessLevel("Medium", 63),
                            DonenessLevel("Medium-well", 68, chef: true)],
                   smokerTempC: 218, minutesPerLb: 7, restMinutes: 5,
                   woodPairing: "Oak",
                   note: "Lean and tender — don't push past medium."),
        GuideEntry(protein: .beef, cut: "Brisket (whole packer)",
                   levels: [DonenessLevel("Probe tender", 96),
                            DonenessLevel("USDA safe", 63, usda: true)],
                   smokerTempC: 121, minutesPerLb: 75, restMinutes: 60,
                   woodPairing: "Post oak",
                   note: "Cook to feel, not just temp — 93–96°C, probes like butter."),
        GuideEntry(protein: .beef, cut: "Beef Short Ribs",
                   levels: [DonenessLevel("Probe tender", 98),
                            DonenessLevel("USDA safe", 63, usda: true)],
                   smokerTempC: 121, minutesPerLb: 70, restMinutes: 30,
                   woodPairing: "Oak or mesquite",
                   note: "Big and beefy; they finish when the meat pulls from the bone."),
        GuideEntry(protein: .beef, cut: "Tri-Tip",
                   levels: [DonenessLevel("Medium-rare", 57),
                            DonenessLevel("Medium", 63),
                            DonenessLevel("Medium-well", 68, chef: true)],
                   smokerTempC: 135, minutesPerLb: 30, restMinutes: 10,
                   woodPairing: "Oak (Santa Maria style)",
                   note: "Reverse sear shines here; slice against the grain."),
        GuideEntry(protein: .beef, cut: "Burgers (ground)",
                   levels: [DonenessLevel("USDA safe", 71, usda: true),
                            DonenessLevel("Medium", 68, chef: true)],
                   smokerTempC: 246, minutesPerLb: 12, restMinutes: 3,
                   woodPairing: "Hickory",
                   note: "Ground beef should reach 71°C / 160°F for safety."),
        GuideEntry(protein: .beef, cut: "Chuck Roast",
                   levels: [DonenessLevel("Probe tender", 96),
                            DonenessLevel("USDA safe", 63, usda: true)],
                   smokerTempC: 121, minutesPerLb: 80, restMinutes: 30,
                   woodPairing: "Hickory or oak",
                   note: "The 'poor man's brisket' — shred or slice at 93–96°C.")
    ]

    // MARK: Pork

    private static let pork: [GuideEntry] = [
        GuideEntry(protein: .pork, cut: "Pork Shoulder (Boston butt)",
                   levels: [DonenessLevel("Pulled", 96),
                            DonenessLevel("Sliceable", 88),
                            DonenessLevel("USDA safe", 63, usda: true)],
                   smokerTempC: 121, minutesPerLb: 90, restMinutes: 45,
                   woodPairing: "Apple or hickory",
                   note: "Pull and shred at ~96°C / 205°F for fall-apart bark."),
        GuideEntry(protein: .pork, cut: "Pork Ribs (spare / St. Louis)",
                   levels: [DonenessLevel("Bend test", 90),
                            DonenessLevel("USDA safe", 63, usda: true)],
                   smokerTempC: 121, minutesPerLb: 60, restMinutes: 15,
                   woodPairing: "Apple or cherry",
                   note: "Done when they bend and crack — ~88–93°C, not falling off bone."),
        GuideEntry(protein: .pork, cut: "Baby Back Ribs",
                   levels: [DonenessLevel("Bend test", 90),
                            DonenessLevel("USDA safe", 63, usda: true)],
                   smokerTempC: 121, minutesPerLb: 50, restMinutes: 10,
                   woodPairing: "Cherry",
                   note: "Leaner and quicker than spares; watch them earlier."),
        GuideEntry(protein: .pork, cut: "Pork Tenderloin",
                   levels: [DonenessLevel("USDA safe", 63, usda: true),
                            DonenessLevel("Medium (juicy)", 60, chef: true)],
                   smokerTempC: 204, minutesPerLb: 20, restMinutes: 5,
                   woodPairing: "Apple",
                   note: "Pull at 63°C / 145°F and rest — a hint of pink is safe and juicy."),
        GuideEntry(protein: .pork, cut: "Pork Chops",
                   levels: [DonenessLevel("USDA safe", 63, usda: true),
                            DonenessLevel("Medium", 60, chef: true)],
                   smokerTempC: 218, minutesPerLb: 14, restMinutes: 5,
                   woodPairing: "Apple or pecan",
                   note: "Thick chops love a reverse sear."),
        GuideEntry(protein: .pork, cut: "Pork Belly (burnt ends)",
                   levels: [DonenessLevel("Tender", 96),
                            DonenessLevel("USDA safe", 63, usda: true)],
                   smokerTempC: 121, minutesPerLb: 60, restMinutes: 15,
                   woodPairing: "Hickory",
                   note: "Cube, smoke, then glaze and braise to candy-soft."),
        GuideEntry(protein: .pork, cut: "Sausage (fresh)",
                   levels: [DonenessLevel("USDA safe", 71, usda: true)],
                   smokerTempC: 135, minutesPerLb: 25, restMinutes: 3,
                   woodPairing: "Pecan",
                   note: "Smoke low so the casing doesn't split before it's done.")
    ]

    // MARK: Poultry

    private static let poultry: [GuideEntry] = [
        GuideEntry(protein: .poultry, cut: "Whole Chicken",
                   levels: [DonenessLevel("USDA safe", 74, usda: true)],
                   smokerTempC: 163, minutesPerLb: 40, restMinutes: 15,
                   woodPairing: "Apple or cherry",
                   note: "Measure the thickest part of the thigh; 74°C / 165°F throughout."),
        GuideEntry(protein: .poultry, cut: "Chicken Thighs",
                   levels: [DonenessLevel("USDA safe", 74, usda: true),
                            DonenessLevel("Tender (dark meat)", 79, chef: true)],
                   smokerTempC: 177, minutesPerLb: 30, restMinutes: 5,
                   woodPairing: "Pecan",
                   note: "Dark meat is even better at 77–79°C — collagen renders."),
        GuideEntry(protein: .poultry, cut: "Chicken Breast",
                   levels: [DonenessLevel("USDA safe", 74, usda: true)],
                   smokerTempC: 177, minutesPerLb: 30, restMinutes: 5,
                   woodPairing: "Apple",
                   note: "Pull right at 74°C / 165°F to keep white meat juicy."),
        GuideEntry(protein: .poultry, cut: "Chicken Wings",
                   levels: [DonenessLevel("USDA safe", 74, usda: true),
                            DonenessLevel("Crispy", 80, chef: true)],
                   smokerTempC: 204, minutesPerLb: 35, restMinutes: 3,
                   woodPairing: "Hickory",
                   note: "Finish hot for crispy skin; safe at 74°C / 165°F."),
        GuideEntry(protein: .poultry, cut: "Whole Turkey",
                   levels: [DonenessLevel("USDA safe", 74, usda: true)],
                   smokerTempC: 163, minutesPerLb: 35, restMinutes: 30,
                   woodPairing: "Cherry or apple",
                   note: "Spatchcock for even cooking; 74°C / 165°F in the thigh."),
        GuideEntry(protein: .poultry, cut: "Turkey Breast",
                   levels: [DonenessLevel("USDA safe", 74, usda: true)],
                   smokerTempC: 163, minutesPerLb: 35, restMinutes: 20,
                   woodPairing: "Apple",
                   note: "Brine first; pull at 74°C / 165°F to avoid dry meat.")
    ]

    // MARK: Fish & seafood

    private static let fish: [GuideEntry] = [
        GuideEntry(protein: .fish, cut: "Salmon Fillet",
                   levels: [DonenessLevel("Medium (flaky)", 52, chef: true),
                            DonenessLevel("USDA safe", 63, usda: true)],
                   smokerTempC: 121, minutesPerLb: 30, restMinutes: 3,
                   woodPairing: "Alder",
                   note: "Many cooks pull at 52–54°C; USDA safe is 63°C / 145°F."),
        GuideEntry(protein: .fish, cut: "Tuna Steak",
                   levels: [DonenessLevel("Rare (seared)", 46, chef: true),
                            DonenessLevel("USDA safe", 63, usda: true)],
                   smokerTempC: 232, minutesPerLb: 8, restMinutes: 2,
                   woodPairing: "None / light oak",
                   note: "Sushi-grade tuna is often seared rare; cook to 63°C for safety."),
        GuideEntry(protein: .fish, cut: "White Fish (cod, halibut)",
                   levels: [DonenessLevel("USDA safe", 63, usda: true)],
                   smokerTempC: 149, minutesPerLb: 20, restMinutes: 2,
                   woodPairing: "Alder",
                   note: "Done when it flakes; 63°C / 145°F and opaque throughout."),
        GuideEntry(protein: .fish, cut: "Shrimp",
                   levels: [DonenessLevel("Done (opaque)", 49, chef: true),
                            DonenessLevel("USDA safe", 63, usda: true)],
                   smokerTempC: 218, minutesPerLb: 6, restMinutes: 1,
                   woodPairing: "None",
                   note: "Cook just until pink and opaque — seconds matter."),
        GuideEntry(protein: .fish, cut: "Whole Trout",
                   levels: [DonenessLevel("USDA safe", 63, usda: true)],
                   smokerTempC: 135, minutesPerLb: 25, restMinutes: 3,
                   woodPairing: "Alder or apple",
                   note: "Skin-on protects the flesh on the grill grates.")
    ]

    // MARK: Lamb

    private static let lamb: [GuideEntry] = [
        GuideEntry(protein: .lamb, cut: "Rack of Lamb",
                   levels: [DonenessLevel("Rare", 52, chef: true),
                            DonenessLevel("Medium-rare", 57),
                            DonenessLevel("Medium", 63),
                            DonenessLevel("USDA safe", 63, usda: true)],
                   smokerTempC: 218, minutesPerLb: 20, restMinutes: 8,
                   woodPairing: "Rosemary + oak",
                   note: "Best at medium-rare; reverse sear for an even pink center."),
        GuideEntry(protein: .lamb, cut: "Leg of Lamb",
                   levels: [DonenessLevel("Medium-rare", 57),
                            DonenessLevel("Medium", 63),
                            DonenessLevel("USDA safe", 63, usda: true)],
                   smokerTempC: 149, minutesPerLb: 25, restMinutes: 15,
                   woodPairing: "Oak or cherry",
                   note: "Bone-in adds flavor; rest well before slicing."),
        GuideEntry(protein: .lamb, cut: "Lamb Shoulder",
                   levels: [DonenessLevel("Pulled", 93),
                            DonenessLevel("USDA safe", 63, usda: true)],
                   smokerTempC: 121, minutesPerLb: 75, restMinutes: 30,
                   woodPairing: "Oak",
                   note: "Low and slow to ~93°C for shreddable, rich meat."),
        GuideEntry(protein: .lamb, cut: "Lamb Chops",
                   levels: [DonenessLevel("Medium-rare", 57),
                            DonenessLevel("Medium", 63),
                            DonenessLevel("USDA safe", 63, usda: true)],
                   smokerTempC: 232, minutesPerLb: 10, restMinutes: 5,
                   woodPairing: "Rosemary + oak",
                   note: "Hot and fast; a quick sear locks in the crust.")
    ]

    // MARK: Vegetables

    private static let veg: [GuideEntry] = [
        GuideEntry(protein: .veg, cut: "Corn on the Cob",
                   levels: [DonenessLevel("Tender", 85, chef: true)],
                   smokerTempC: 204, minutesPerLb: 20, restMinutes: 2,
                   woodPairing: "Any fruit wood",
                   note: "Grill in the husk for steam, or bare for char."),
        GuideEntry(protein: .veg, cut: "Portobello Mushrooms",
                   levels: [DonenessLevel("Tender", 75, chef: true)],
                   smokerTempC: 204, minutesPerLb: 12, restMinutes: 2,
                   woodPairing: "Hickory",
                   note: "Marinate first; they soak up smoke beautifully."),
        GuideEntry(protein: .veg, cut: "Bell Peppers",
                   levels: [DonenessLevel("Charred & soft", 80, chef: true)],
                   smokerTempC: 232, minutesPerLb: 10, restMinutes: 2,
                   woodPairing: "Any",
                   note: "Blister the skins, then steam in a bowl to peel."),
        GuideEntry(protein: .veg, cut: "Sweet Potatoes",
                   levels: [DonenessLevel("Fork tender", 96, chef: true)],
                   smokerTempC: 177, minutesPerLb: 45, restMinutes: 5,
                   woodPairing: "Pecan",
                   note: "Smoke whole until a probe slides in with no resistance.")
    ]
}
