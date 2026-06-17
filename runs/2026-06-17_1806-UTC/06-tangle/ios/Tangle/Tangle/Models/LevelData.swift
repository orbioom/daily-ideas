import Foundation

/// All hand-authored content for Tangle. Each level lists a base word and the
/// target words formable from it (verified count-aware by `LetterMultiset`).
/// The `CrosswordPacker` arranges target words into a grid at runtime; words it
/// cannot place still reward the player as bonus words.
enum LevelData {

    static let packs: [LevelPack] = [garden, voyage, harvest]

    /// Flat ordered list of every level across all packs.
    static var allLevels: [Level] { packs.flatMap { $0.levels } }

    static func level(withID id: String) -> Level? {
        allLevels.first { $0.id == id }
    }

    static func pack(forLevelID id: String) -> LevelPack? {
        packs.first { pack in pack.levels.contains { $0.id == id } }
    }

    /// Zero-based index of a level within the full ordered list.
    static func globalIndex(of id: String) -> Int? {
        allLevels.firstIndex { $0.id == id }
    }

    // MARK: - Pack 1: Garden (free)

    static let garden = LevelPack(
        id: "garden",
        title: "Garden Path",
        subtitle: "Gentle starters to find your footing",
        symbol: "leaf.fill",
        requiresPro: false,
        levels: [
            Level(id: "garden-01", title: "Sprout", baseWord: "SEED",
                  targetWords: ["SEE", "SEED", "DEE"],
                  extraBonusWords: ["EDS"]),
            Level(id: "garden-02", title: "Bloom", baseWord: "PLANT",
                  targetWords: ["PLAN", "PLANT", "PANT", "LAP", "TAP", "NAP", "ANT", "PAL"],
                  extraBonusWords: ["APT", "PAN", "TAN"]),
            Level(id: "garden-03", title: "Petal", baseWord: "ROSE",
                  targetWords: ["ROSE", "SORE", "ORE", "ROE", "ORES", "EROS"],
                  extraBonusWords: ["RES", "OES"]),
            Level(id: "garden-04", title: "Border", baseWord: "GARDEN",
                  targetWords: ["GARDEN", "DANGER", "RANGED", "GRADE", "RANGE", "ANGER", "GRAND",
                                "DEAR", "DARE", "READ", "NEAR", "EARN", "GEAR", "DEAN", "RAGE"],
                  extraBonusWords: ["GNAR", "AGER", "REDAN"]),
            Level(id: "garden-05", title: "Trellis", baseWord: "FLOWER",
                  targetWords: ["FLOWER", "FOWLER", "LOWER", "FLOW", "WOLF", "WORE", "ROLE",
                                "FORE", "FLEW", "OWE", "ROW", "LOW", "ORE", "ELF"],
                  extraBonusWords: ["FLOE", "WERO", "REFLOW"]),
            Level(id: "garden-06", title: "Orchard", baseWord: "ORANGE",
                  targetWords: ["ORANGE", "ONAGER", "ARGON", "GROAN", "ORGAN", "ANGER", "RANGE",
                                "GONE", "GEAR", "NEAR", "EARN", "RAGE", "ROAN", "OGRE"],
                  extraBonusWords: ["NAGOR", "GENOA"])
        ]
    )

    // MARK: - Pack 2: Voyage (Pro)

    static let voyage = LevelPack(
        id: "voyage",
        title: "Voyage",
        subtitle: "Coastlines, sails and far horizons",
        symbol: "sailboat.fill",
        requiresPro: true,
        levels: [
            Level(id: "voyage-01", title: "Harbor", baseWord: "ISLAND",
                  targetWords: ["ISLAND", "LANDS", "SNAIL", "NAILS", "SAND", "LAND", "SAIL",
                                "DIAL", "LAID", "SLID", "AIDS", "AILS", "LADS"],
                  extraBonusWords: ["DINAS", "NIDAL"]),
            Level(id: "voyage-02", title: "Anchor", baseWord: "OCEAN",
                  targetWords: ["OCEAN", "CANOE", "ACNE", "CONE", "ONCE", "CANE", "ACE",
                                "CAN", "EON", "OCA", "CON", "ECO"],
                  extraBonusWords: ["NAE"]),
            Level(id: "voyage-03", title: "Compass", baseWord: "SAILOR",
                  targetWords: ["SAILOR", "RIALS", "RAILS", "ROILS", "LIARS", "LIRAS", "SOLAR",
                                "ORALS", "SAIL", "RAIL", "OARS", "SOIL", "LIAR", "AILS"],
                  extraBonusWords: ["LORIS", "ROILS", "SORAL"]),
            Level(id: "voyage-04", title: "Lantern", baseWord: "MARINE",
                  targetWords: ["MARINE", "AIRMEN", "REMAIN", "MINER", "MARNE", "MANE", "MAIN",
                                "RAIN", "MINE", "RIME", "NEAR", "EARN", "MEAN", "RANI"],
                  extraBonusWords: ["AMINE", "RAMIE", "MARINE"]),
            Level(id: "voyage-05", title: "Tideline", baseWord: "BREEZE",
                  targetWords: ["BREEZE", "BEER", "BEE", "REE", "ERE", "BREE", "ZEE", "BEEZ"],
                  extraBonusWords: ["REZ", "BEZ"])
        ]
    )

    // MARK: - Pack 3: Harvest (Pro)

    static let harvest = LevelPack(
        id: "harvest",
        title: "Harvest Moon",
        subtitle: "Cozy autumn afternoons",
        symbol: "moon.stars.fill",
        requiresPro: true,
        levels: [
            Level(id: "harvest-01", title: "Lantern", baseWord: "AUTUMN",
                  targetWords: ["AUTUMN", "MAUN", "MAN", "TAN", "NUT", "TAU", "AUNT",
                                "TUNA", "TUN", "MUT", "UNAU"],
                  extraBonusWords: ["UTA", "NAM"]),
            Level(id: "harvest-02", title: "Maple", baseWord: "MAPLE",
                  targetWords: ["MAPLE", "AMPLE", "LAMP", "MEAL", "MALE", "LEAP", "PALE",
                                "PEAL", "PLEA", "LAME", "MAP", "PAL", "LAP", "APE"],
                  extraBonusWords: ["PELMA", "AMPLE"]),
            Level(id: "harvest-03", title: "Cider", baseWord: "CIDER",
                  targetWords: ["CIDER", "CRIED", "DICER", "RICED", "RICE", "DICE", "RIDE",
                                "DIRE", "CRED", "RED", "ICE", "DIE", "IRE", "RID"],
                  extraBonusWords: ["CIRE", "DREI"]),
            Level(id: "harvest-04", title: "Pumpkin", baseWord: "BASKET",
                  targetWords: ["BASKET", "BEAKS", "BAKES", "BEATS", "BEAST", "BATES", "TAKES",
                                "STEAK", "STAKE", "SKATE", "BASE", "BEAT", "TASK", "BAKE"],
                  extraBonusWords: ["KEBAS", "TABES"]),
            Level(id: "harvest-05", title: "Bonfire", baseWord: "EMBERS",
                  targetWords: ["EMBERS", "EMBER", "BEERS", "MERES", "MERE", "BEER", "SEEM",
                                "BEES", "REBS", "BEMS", "BREES", "BREE"],
                  extraBonusWords: ["EMES", "BERMS"])
        ]
    )

    // MARK: - Daily puzzle base words

    /// Curated base words for the daily puzzle. A date-seeded index selects one.
    static let dailyBaseWords: [String] = [
        "GARDEN", "ORANGE", "ISLAND", "MARINE", "SAILOR", "BASKET",
        "FLOWER", "EMBERS", "AUTUMN", "PLANTS", "STREAM", "MASTER",
        "SILVER", "PLANET", "FOREST", "WINTER", "BREATH", "CASTLE",
        "DANCER", "SECOND", "HUNTER", "MELODY", "PEPPER", "SPRING"
    ]

    /// Target words for each daily base word, keyed by the base word.
    static let dailyTargets: [String: [String]] = [
        "GARDEN": ["GARDEN", "DANGER", "RANGED", "GRADE", "RANGE", "ANGER", "GRAND", "DEAR", "DARE", "READ", "NEAR", "EARN", "GEAR", "RAGE"],
        "ORANGE": ["ORANGE", "ONAGER", "ARGON", "GROAN", "ORGAN", "ANGER", "RANGE", "GONE", "GEAR", "NEAR", "EARN", "RAGE", "ROAN", "OGRE"],
        "ISLAND": ["ISLAND", "LANDS", "SNAIL", "NAILS", "SAND", "LAND", "SAIL", "DIAL", "LAID", "SLID", "AIDS", "AILS", "LADS"],
        "MARINE": ["MARINE", "AIRMEN", "REMAIN", "MINER", "MANE", "MAIN", "RAIN", "MINE", "RIME", "NEAR", "EARN", "MEAN", "RANI"],
        "SAILOR": ["SAILOR", "RIALS", "RAILS", "ROILS", "LIARS", "SOLAR", "ORALS", "SAIL", "RAIL", "OARS", "SOIL", "LIAR", "AILS"],
        "BASKET": ["BASKET", "BEAKS", "BAKES", "BEATS", "BEAST", "TAKES", "STEAK", "STAKE", "SKATE", "BASE", "BEAT", "TASK", "BAKE"],
        "FLOWER": ["FLOWER", "FOWLER", "LOWER", "FLOW", "WOLF", "WORE", "ROLE", "FORE", "FLEW", "OWE", "ROW", "LOW", "ORE", "ELF"],
        "EMBERS": ["EMBERS", "EMBER", "BEERS", "MERES", "MERE", "BEER", "SEEM", "BEES", "REBS", "BEMS"],
        "AUTUMN": ["AUTUMN", "MAUN", "MAN", "TAN", "NUT", "AUNT", "TUNA", "TUN", "MUT", "UNAU"],
        "PLANTS": ["PLANTS", "PLANT", "PLANS", "PLAN", "PANTS", "SLANT", "SPLAT", "PANT", "LAST", "SALT", "SLAP", "SNAP", "TAPS"],
        "STREAM": ["STREAM", "MASTER", "TAMERS", "MATES", "MEATS", "STEAM", "TEAMS", "TAMES", "SMART", "MARS", "ARMS", "STAR", "RATE"],
        "MASTER": ["MASTER", "STREAM", "TAMERS", "MATES", "MEATS", "STEAM", "TEAMS", "TAMES", "SMART", "MARS", "ARMS", "STAR", "RATE"],
        "SILVER": ["SILVER", "LIVERS", "LIVRES", "SLIVER", "LIVER", "LIVES", "LIRES", "VILES", "VEILS", "LIVE", "VILE", "SIRE", "RISE"],
        "PLANET": ["PLANET", "PLATEN", "PLANE", "PLATE", "PLEAT", "PETAL", "PANEL", "LEANT", "PLAN", "LEAP", "PALE", "TALE", "LANE"],
        "FOREST": ["FOREST", "FORTES", "FOSTER", "SOFTER", "FORTE", "STORE", "FORTS", "FROST", "SORE", "REST", "SORT", "TOES", "FRET"],
        "WINTER": ["WINTER", "TWINER", "WRITE", "TWINE", "WREN", "WINE", "WIRE", "TIRE", "RITE", "WENT", "RENT", "TINE"],
        "BREATH": ["BREATH", "BATHER", "BERTHA", "BERTH", "BREAT", "BEAR", "BEAT", "BATH", "HEAR", "HEART", "HATE", "RATE", "HARE"],
        "CASTLE": ["CASTLE", "CLEATS", "ECLATS", "LACES", "CASTE", "CLEAT", "SCALE", "LEAST", "STEAL", "TALES", "CASE", "LACE", "SEAL"],
        "DANCER": ["DANCER", "CANDER", "NACRED", "DANCE", "CANED", "ACRED", "CARED", "CEDAR", "RACED", "ACNE", "CANE", "RACE", "CARD"],
        "SECOND": ["SECOND", "CODENS", "CONES", "CODES", "SCONE", "CEDOS", "DONES", "NODES", "CODE", "CONE", "DOSE", "NODE", "ONCE"],
        "HUNTER": ["HUNTER", "HUNT", "HURT", "THEN", "HERN", "TURN", "RUNT", "RENT", "TUNE", "HUE", "NUT", "RUE"],
        "MELODY": ["MELODY", "MODEL", "YODEL", "MODE", "DOLE", "LODE", "MOLE", "MELD", "MOLD", "OLDY", "DOME", "ELD", "LYE"],
        "PEPPER": ["PEPPER", "PREP", "PEER", "PEEP", "PEP", "PER", "REP", "PEE", "ERE", "REE"],
        "SPRING": ["SPRING", "PRIGS", "GRINS", "RINGS", "PINGS", "SPRIG", "GRIN", "RING", "PINS", "SING", "SIGN", "GRIP", "RIGS"]
    ]
}
