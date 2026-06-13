import Foundation

/// The hand-authored, fully offline puzzle bank. No giant dictionary ships —
/// each puzzle carries its own curated accepted-word list. Every puzzle is
/// built from a real pangram (a common word with exactly seven distinct
/// letters); that word's letters become the set, and one becomes the required
/// centre. Each `answers` list was hand-checked so every entry is a real
/// English word, ≥4 letters, contains the centre, and uses only the seven
/// letters (repeats allowed). Lowercase, no proper nouns, no hyphens/spaces.
///
/// The free bank is `core` (28 puzzles); `proPack` adds an extra set gated
/// behind Hive Pro. Daily and Archive draw only from `core` so the free game
/// is complete on its own.
enum PuzzleBank {
    /// Puzzles available for play given the current Pro state.
    static func all(includePro: Bool) -> [Puzzle] {
        includePro ? core + proPack : core
    }

    /// Look up a puzzle by id across both packs (Pro included), or nil.
    static func puzzle(id: Int) -> Puzzle? {
        (core + proPack).first { $0.id == id }
    }

    /// The free, always-available puzzles. Daily/Archive index into this list.
    static let core: [Puzzle] = [
        Puzzle(id: 0, letters: ["p", "a", "i", "n", "t", "e", "d"], center: "t",
               answers: ["paint", "painted", "pant", "panted", "pinta", "tepid", "taped", "tape", "tend", "tent", "tide", "tied", "tine", "tint", "taint", "titan", "attend", "attain", "attained", "dent", "date", "data", "detain", "neat", "pita", "pint", "pent", "dint", "intend"],
               pangrams: ["painted"]),
        Puzzle(id: 1, letters: ["c", "r", "e", "a", "t", "i", "n"], center: "t",
               answers: ["creatin", "react", "recta", "trace", "train", "trait", "treat", "tract", "tier", "tire", "tine", "tint", "tart", "tear", "teat", "tent", "tarn", "cart", "cater", "crate", "certain", "centre", "retain", "retina", "attire", "intact", "interact", "natter", "tatter", "titan", "nitrate", "citrate", "attract"],
               pangrams: ["creatin", "certain", "interact"]),
        Puzzle(id: 2, letters: ["g", "a", "r", "d", "e", "n", "s"], center: "e",
               answers: ["gardens", "garden", "gander", "danger", "ranger", "ranges", "ranged", "grade", "grades", "graded", "grenade", "sedan", "sedans", "saner", "dense", "denser", "sender", "render", "renders", "eared", "genera", "regards", "regard", "geared", "reads", "dears", "dread", "dreads", "nears", "gears", "anger", "angers", "agree", "agreed", "agrees", "deans", "erase", "eased", "ease", "near", "sneer", "sneered"],
               pangrams: ["gardens"]),
        Puzzle(id: 3, letters: ["m", "o", "n", "a", "r", "c", "h"], center: "r",
               answers: ["monarch", "march", "charm", "ranch", "macron", "carom", "cram", "harm", "roach", "roam", "roar", "arch", "char", "corm", "acorn", "anchor", "roman"],
               pangrams: ["monarch"]),
        Puzzle(id: 4, letters: ["b", "l", "a", "n", "k", "e", "t"], center: "e",
               answers: ["blanket", "bleak", "bleat", "label", "kale", "lake", "lane", "lean", "leant", "bake", "bale", "bane", "bate", "beak", "bean", "beat", "bent", "belt", "enable", "tenable", "teak"],
               pangrams: ["blanket"]),
        Puzzle(id: 5, letters: ["c", "r", "u", "m", "b", "l", "e"], center: "r",
               answers: ["crumble", "rumble", "cruel", "curb", "curl", "cure", "crumb", "umber", "lure", "rule", "ruble", "burl"],
               pangrams: ["crumble"]),
        Puzzle(id: 6, letters: ["c", "l", "o", "t", "h", "e", "s"], center: "e",
               answers: ["clothes", "close", "closet", "echo", "echoes", "else", "hose", "holes", "hotel", "hotels", "chose", "shoe", "sole", "stole", "soothe", "those", "etch"],
               pangrams: ["clothes"]),
        Puzzle(id: 7, letters: ["g", "a", "r", "b", "l", "e", "d"], center: "e",
               answers: ["garbled", "gabble", "gable", "glade", "grade", "grabbed", "garble", "bagel", "badge", "bread", "breed", "beard", "bead", "barge", "label", "regale", "ragged", "dredge", "ledge", "eager", "dabble", "babble"],
               pangrams: ["garbled"]),
        Puzzle(id: 8, letters: ["j", "u", "n", "i", "p", "e", "r"], center: "i",
               answers: ["juniper", "ruin", "prier", "urine", "unripe", "pier", "pine", "rein", "ripe", "nine", "nipper"],
               pangrams: ["juniper"]),
        Puzzle(id: 9, letters: ["v", "a", "m", "p", "i", "r", "e"], center: "i",
               answers: ["vampire", "empire", "prime", "primer", "pair", "pier", "amir", "ramie", "prim", "ripe", "rime", "mire"],
               pangrams: ["vampire"]),
        Puzzle(id: 10, letters: ["t", "u", "r", "k", "e", "y", "s"], center: "e",
               answers: ["turkeys", "turkey", "trek", "ekes", "reuse", "user", "ruse", "rest", "trey", "true", "trues", "yest", "suety"],
               pangrams: ["turkeys"]),
        Puzzle(id: 11, letters: ["w", "i", "z", "a", "r", "d", "s"], center: "i",
               answers: ["wizards", "wizard", "dais", "arid", "raid", "raids", "said", "sari", "radii"],
               pangrams: ["wizards"]),
        Puzzle(id: 12, letters: ["h", "i", "s", "t", "o", "r", "y"], center: "i",
               answers: ["history", "shirt", "hits", "shit", "this", "trio", "trios", "riot", "riots", "stir", "tori", "shirty", "thirsty"],
               pangrams: ["history"]),
        Puzzle(id: 13, letters: ["c", "r", "a", "y", "o", "n", "s"], center: "o",
               answers: ["crayons", "crayon", "corns", "acorn", "arson", "roans", "scorn", "sonar", "crony", "rayon", "racon", "orca", "cosy"],
               pangrams: ["crayons"]),
        Puzzle(id: 14, letters: ["p", "e", "l", "i", "c", "a", "n"], center: "e",
               answers: ["pelican", "pencil", "panel", "place", "plane", "clean", "lance", "lapel", "cape", "cane", "epic", "peal", "pecan", "plea", "penal", "nape", "capelin"],
               pangrams: ["pelican", "capelin"]),
        Puzzle(id: 15, letters: ["o", "r", "g", "a", "n", "i", "c"], center: "g",
               answers: ["organic", "gain", "going", "gong", "grain", "groan", "grog", "grin", "cargo", "conga", "raging", "gang", "garni"],
               pangrams: ["organic"]),
        Puzzle(id: 16, letters: ["s", "u", "b", "j", "e", "c", "t"], center: "u",
               answers: ["subject", "just", "jube", "jutes", "tube", "tubes", "tubs", "bust", "busts", "cube", "cubes", "cubs", "cues", "suet", "stub", "subset"],
               pangrams: ["subject"]),
        Puzzle(id: 17, letters: ["k", "e", "t", "c", "h", "u", "p"], center: "e",
               answers: ["ketchup", "chute", "cheek", "check", "cheep", "keep", "kept", "ketch", "puke", "peck", "tech", "etch"],
               pangrams: ["ketchup"]),
        Puzzle(id: 18, letters: ["d", "a", "n", "c", "e", "r", "s"], center: "e",
               answers: ["dancers", "dancer", "dances", "dance", "cedars", "cared", "cadre", "scared", "sacred", "caned", "canes", "cane", "cease", "ceased", "cedar", "dare", "dares", "dear", "dears", "endear", "deans", "eared", "near", "nears", "races", "raced", "racer", "reads", "erase", "eased", "scene", "screed", "sander", "arced"],
               pangrams: ["dancers"]),
        Puzzle(id: 19, letters: ["p", "l", "a", "n", "e", "t", "s"], center: "e",
               answers: ["planets", "planet", "plates", "plate", "slate", "stale", "steal", "pleat", "pleats", "petal", "petals", "slept", "spelt", "spent", "leant", "lean", "leap", "leaps", "lane", "lanes", "lapse", "pane", "panel", "pastel", "taels", "tales", "nape", "napes", "pleas", "penal"],
               pangrams: ["planets"]),
        Puzzle(id: 20, letters: ["m", "a", "s", "o", "n", "r", "y"], center: "o",
               answers: ["masonry", "mason", "masons", "moans", "moan", "roams", "roam", "roan", "roans", "morn", "moray", "norm", "aroma", "roman", "rayon", "oars", "soar", "sonar"],
               pangrams: ["masonry"]),
        Puzzle(id: 21, letters: ["b", "r", "a", "c", "k", "e", "t"], center: "e",
               answers: ["bracket", "brake", "break", "beak", "bear", "beat", "beta", "cake", "care", "cater", "crate", "take", "taker", "tear", "teak", "treat", "react", "recta", "acre", "baker"],
               pangrams: ["bracket"]),
        Puzzle(id: 22, letters: ["f", "l", "o", "u", "n", "c", "e"], center: "o",
               answers: ["flounce", "floe", "foul", "cone", "clone", "cool", "fool", "lone", "noel", "ounce", "once", "colon"],
               pangrams: ["flounce"]),
        Puzzle(id: 23, letters: ["g", "a", "r", "n", "i", "s", "h"], center: "i",
               answers: ["garnish", "hairs", "nigh", "sigh", "shin", "grain", "rains", "raisin", "airing", "arising", "airs"],
               pangrams: ["garnish"]),
        Puzzle(id: 24, letters: ["p", "l", "u", "m", "a", "g", "e"], center: "e",
               answers: ["plumage", "gleam", "glume", "male", "mule", "mage", "page", "pale", "plea", "peal", "gale", "ample", "maple", "league", "plague"],
               pangrams: ["plumage"]),
        Puzzle(id: 25, letters: ["s", "u", "b", "t", "l", "e", "r"], center: "e",
               answers: ["subtler", "bluest", "bluet", "brute", "brutes", "butler", "lubes", "rebus", "rebut", "ruble", "rubles", "tuber", "tubers", "true", "trues", "blue", "blues", "lure", "lures"],
               pangrams: ["subtler"]),
        Puzzle(id: 26, letters: ["c", "r", "u", "m", "b", "e", "d"], center: "e",
               answers: ["crumbed", "cube", "cubed", "cuber", "cured", "curbed", "cumber", "deuce", "demur", "umber", "crude"],
               pangrams: ["crumbed"]),
        Puzzle(id: 27, letters: ["l", "e", "a", "d", "i", "n", "g"], center: "i",
               answers: ["leading", "dealing", "gained", "nailed", "denial", "ailing", "aiding", "gelid", "glide", "align", "liane", "ideal", "indie", "linage", "genial", "aging", "idea", "agile", "ailed", "nidal"],
               pangrams: ["leading", "dealing"]),
    ]

    /// Hive Pro adds this extra puzzle pack.
    static let proPack: [Puzzle] = [
        Puzzle(id: 28, letters: ["t", "e", "a", "r", "i", "n", "g"], center: "i",
               answers: ["tearing", "granite", "tangier", "retain", "retina", "ratine", "gaiter", "gainer", "earing", "airing", "reign", "nitre", "tinier", "triage", "taring", "grain", "grit", "gain", "girt"],
               pangrams: ["tearing", "granite", "tangier"]),
        Puzzle(id: 29, letters: ["s", "e", "c", "t", "i", "o", "n"], center: "o",
               answers: ["section", "notice", "noetic", "conies", "cosine", "coin", "coins", "icon", "icons", "onset", "stone", "tones", "tonic", "toes", "once", "cento", "scion", "ionic", "notion", "eosin", "coon"],
               pangrams: ["section"]),
        Puzzle(id: 30, letters: ["o", "u", "t", "s", "i", "d", "e"], center: "o",
               answers: ["outside", "studio", "tedious", "dotes", "doest", "toed", "odes", "oust", "outdo", "todies", "tods", "outed", "stood"],
               pangrams: ["outside", "tedious"]),
        Puzzle(id: 31, letters: ["d", "i", "l", "a", "t", "e", "s"], center: "i",
               answers: ["dilates", "detail", "tailed", "listed", "staid", "stile", "slide", "islet", "aisle", "tilde", "tides", "tiled", "tiles", "dials", "distal", "aside"],
               pangrams: ["dilates"]),
        Puzzle(id: 32, letters: ["c", "o", "m", "p", "u", "t", "e"], center: "u",
               answers: ["compute", "cute", "pump", "puce", "coup", "coupe", "pout", "outcome", "mute", "moue", "mutt"],
               pangrams: ["compute"]),
        Puzzle(id: 33, letters: ["d", "u", "s", "t", "p", "a", "n"], center: "a",
               answers: ["dustpan", "pandas", "naps", "nada", "pant", "pants", "pads", "span", "spat", "stand", "tans", "tuna", "sand", "taps"],
               pangrams: ["dustpan"]),
        Puzzle(id: 34, letters: ["b", "l", "a", "n", "k", "e", "r"], center: "e",
               answers: ["blanker", "banker", "barker", "beaker", "bleak", "bleaker", "break", "baker", "baler", "kernel", "rankle", "knee", "earl", "earn", "lean", "leak", "leaker"],
               pangrams: ["blanker"]),
    ]
}
