import Foundation

/// The authored library of mini and midi crosswords. Each puzzle is a solution
/// grid plus a clue for every derived slot; the CrosswordEngine derives the
/// numbering, slots, and answers from the grid at runtime. Every across and down
/// run of length >= 2 is a real English word with exactly one clue.
enum PuzzleBank {
    /// All puzzles, in stable order. The daily picker indexes into this array.
    static let all: [Puzzle] = [
        Puzzle(
            id: "px-001",
            title: "Full House",
            difficulty: .medium,
            grid: ["HAVOC", "AROMA", "VOTER", "OMEGA", "CARAT"],
            acrossClues: [1: "Widespread destruction", 6: "Pleasant smell", 7: "One who casts a ballot", 8: "Last Greek letter", 9: "Gem weight unit"],
            downClues: [1: "Widespread destruction", 2: "Pleasant smell", 3: "One who casts a ballot", 4: "Last Greek letter", 5: "Gem weight unit"]
        ),
        Puzzle(
            id: "px-002",
            title: "Open Book",
            difficulty: .medium,
            grid: ["MORPH", "OPERA", "RESIN", "PRIED", "HANDY"],
            acrossClues: [1: "Change shape gradually", 6: "Sung dramatic work", 7: "Sticky tree secretion", 8: "Forced open; snooped", 9: "Useful; skilled with tools"],
            downClues: [1: "Change shape gradually", 2: "Sung dramatic work", 3: "Sticky tree secretion", 4: "Forced open; snooped", 5: "Useful; skilled with tools"]
        ),
        Puzzle(
            id: "px-003",
            title: "Tight Weave",
            difficulty: .hard,
            grid: ["RETRO", "EGRET", "TROUT", "REUSE", "OTTER"],
            acrossClues: [1: "Old-fashioned in a cool way", 6: "Long-legged white wading bird", 7: "Speckled stream fish", 8: "Use again", 9: "Playful river mammal"],
            downClues: [1: "Old-fashioned in a cool way", 2: "Long-legged white wading bird", 3: "Speckled stream fish", 4: "Use again", 5: "Playful river mammal"]
        ),
        Puzzle(
            id: "px-004",
            title: "Dawn Patrol",
            difficulty: .easy,
            grid: ["OH###", "AORTA", "FOYER", "STEAM", "###MY"],
            acrossClues: [1: "Cry of surprise", 3: "Largest artery in the body", 7: "Entrance hall", 8: "Vapor from boiling water", 9: "Belonging to me"],
            downClues: [1: "Clumsy fools", 2: "Owl's call", 4: "Whiskey grain; deli bread", 5: "Group playing together", 6: "Land military force"]
        ),
        Puzzle(
            id: "px-005",
            title: "Easy Does It",
            difficulty: .easy,
            grid: ["AT###", "RESIN", "ERODE", "ANNEX", "###AT"],
            acrossClues: [1: "Located in", 3: "Sticky tree secretion", 7: "Wear away gradually", 8: "Add on, as a building wing", 9: "Located in"],
            downClues: [1: "Region or square footage", 2: "Slender coastal seabird", 4: "Male child", 5: "A bright thought", 6: "Coming immediately after"]
        ),
        Puzzle(
            id: "px-006",
            title: "Summer Start",
            difficulty: .easy,
            grid: ["JUNE#", "USUAL", "NUTTY", "EATER", "#LYRE"],
            acrossClues: [1: "Month before July", 5: "Customary", 7: "Crazy; tasting of almonds", 8: "One who dines", 9: "Small ancient harp"],
            downClues: [1: "Month before July", 2: "Customary", 3: "Crazy; tasting of almonds", 4: "One who dines", 6: "Small ancient harp"]
        ),
        Puzzle(
            id: "px-007",
            title: "Drift Away",
            difficulty: .easy,
            grid: ["#WAFT", "DICEY", "USURP", "METRO", "PREY#"],
            acrossClues: [1: "Float gently on the air", 5: "Risky", 6: "Seize power wrongfully", 7: "Big-city subway system", 8: "Hunted animal"],
            downClues: [1: "More sensible", 2: "Sharp, as an angle under 90°", 3: "Boat that carries passengers across", 4: "A typing mistake", 5: "Drop off carelessly; a landfill"]
        ),
        Puzzle(
            id: "px-008",
            title: "Bullseye",
            difficulty: .medium,
            grid: ["VOILA", "OFFAL", "IF#YE", "LAYER", "ALERT"],
            acrossClues: [1: "'There it is!' in French", 6: "Animal organ meat", 7: "On the condition that", 8: "'You,' archaically", 9: "One thickness in a stack", 11: "On guard; a warning notice"],
            downClues: [1: "'There it is!' in French", 2: "Animal organ meat", 3: "On the condition that", 4: "One thickness in a stack", 5: "On guard; a warning notice", 10: "'You,' archaically"]
        ),
        Puzzle(
            id: "px-009",
            title: "Stepping Stones",
            difficulty: .medium,
            grid: ["USES#", "SWATH", "#EGO#", "TALON", "#REDO"],
            acrossClues: [1: "Employs", 5: "A broad strip", 6: "Sense of self-importance", 7: "Bird's claw", 9: "Do over again"],
            downClues: [1: "You and me", 2: "Vow; to curse", 3: "Bald national bird of the U.S.", 4: "Was on one's feet", 8: "Negative reply"]
        ),
        Puzzle(
            id: "px-010",
            title: "Switchback",
            difficulty: .medium,
            grid: ["#SASH", "CHILI", "#USE#", "INLET", "STEP#"],
            acrossClues: [1: "Window frame; a waist band", 5: "Spicy stew, or a hot pepper", 6: "Put into service", 7: "Small coastal bay", 8: "A single stride; a stair"],
            downClues: [1: "Divert to a side track", 2: "Walkway between seats", 3: "Nightly rest", 4: "Casual greeting", 7: "Exists, third-person"]
        ),
        Puzzle(
            id: "px-011",
            title: "Picture Frame",
            difficulty: .medium,
            grid: ["SIPS#", "IDLER", "PLANE", "SENSE", "#REED"],
            acrossClues: [1: "Drinks in small amounts", 5: "A lazy person", 7: "Aircraft; a woodworking tool", 8: "Sight, smell, or touch", 9: "Marsh grass; clarinet part"],
            downClues: [1: "Drinks in small amounts", 2: "A lazy person", 3: "Aircraft; a woodworking tool", 4: "Sight, smell, or touch", 6: "Marsh grass; clarinet part"]
        ),
        Puzzle(
            id: "px-012",
            title: "Up the Stairs",
            difficulty: .hard,
            grid: ["BEE##", "EVERY", "EERIE", "FRILL", "##EEL"],
            acrossClues: [1: "Honey maker", 4: "Each and all", 7: "Strange and spooky", 8: "Decorative ruffle", 9: "Snakelike fish"],
            downClues: [1: "Cattle meat, or a complaint", 2: "At any time", 3: "Strange and spooky", 5: "Irritate or anger", 6: "Shout loudly"]
        ),
        Puzzle(
            id: "px-013",
            title: "Down the Stairs",
            difficulty: .hard,
            grid: ["##COT", "SCOUR", "WORSE", "IRATE", "GEL##"],
            acrossClues: [1: "Folding bed", 4: "Scrub hard; search thoroughly", 6: "More bad", 7: "Very angry", 8: "Hair styling goo"],
            downClues: [1: "Reef-building sea organism", 2: "Force out of office", 3: "Tall woody plant", 4: "A big gulp", 5: "Apple's center"]
        ),
        Puzzle(
            id: "px-014",
            title: "Sharp Turn",
            difficulty: .easy,
            grid: ["SUM##", "TROOP", "ABOVE", "NASAL", "KNELT"],
            acrossClues: [1: "Total of addition", 4: "Group of soldiers or scouts", 7: "Higher than", 8: "Of the nose", 9: "Got down on a knee"],
            downClues: [1: "Smelled bad, in the past", 2: "Of the city", 3: "Largest deer, with broad antlers", 5: "Egg shape", 6: "Animal hide; to pummel"]
        ),
        Puzzle(
            id: "px-015",
            title: "Hairpin",
            difficulty: .easy,
            grid: ["LOACH", "UNDUE", "STERN", "TOPIC", "##TOE"],
            acrossClues: [1: "Small freshwater bottom fish", 6: "Excessive; not warranted", 7: "Strict; a boat's rear", 8: "Subject of discussion", 9: "Foot digit"],
            downClues: [1: "Strong craving", 2: "Aware of; on top of", 3: "Highly skilled", 4: "Small unusual collectible", 5: "Therefore"]
        ),
        Puzzle(
            id: "px-016",
            title: "Wide Open",
            difficulty: .hard,
            grid: ["TIMID", "INANE", "MANGA", "INGOT", "DEATH"],
            acrossClues: [1: "Shy and nervous", 6: "Silly and pointless", 7: "Japanese comic style", 8: "Cast bar of metal", 9: "The end of life"],
            downClues: [1: "Shy and nervous", 2: "Silly and pointless", 3: "Japanese comic style", 4: "Cast bar of metal", 5: "The end of life"]
        ),
        Puzzle(
            id: "px-017",
            title: "Clean Slate",
            difficulty: .hard,
            grid: ["PRISM", "LANCE", "AVERT", "TEPEE", "ENTER"],
            acrossClues: [1: "Light-splitting glass shape", 6: "Knight's long spear", 7: "Turn away; prevent", 8: "Conical Native American tent", 9: "Go in; a keyboard key"],
            downClues: [1: "Dinner dish", 2: "Glossy black bird of Poe", 3: "Clumsy or incompetent", 4: "Loose mountain-slope rock", 5: "Basic unit of length"]
        ),
        Puzzle(
            id: "px-018",
            title: "Slant Rhyme",
            difficulty: .medium,
            grid: ["VOWS#", "OCEAN", "WE#LO", "SALVE", "#NOEL"],
            acrossClues: [1: "Solemn promises", 5: "Vast body of saltwater", 7: "You and I", 8: "'Behold!' of old", 9: "Soothing ointment", 11: "A Christmas carol"],
            downClues: [1: "Solemn promises", 2: "Vast body of saltwater", 3: "You and I", 4: "Soothing ointment", 6: "A Christmas carol", 10: "'Behold!' of old"]
        ),
        Puzzle(
            id: "px-019",
            title: "Pinwheel",
            difficulty: .medium,
            grid: ["WON##", "AVIAN", "GENRE", "ENTER", "##HAD"],
            acrossClues: [1: "Came in first", 4: "Of or relating to birds", 7: "Category of art or music", 8: "Go in; a keyboard key", 9: "Possessed, in the past"],
            downClues: [1: "Pay for work; to carry on", 2: "Kitchen baking appliance", 3: "Position after eighth", 5: "Region or square footage", 6: "Studious enthusiast"]
        ),
        Puzzle(
            id: "px-020",
            title: "Crossbars",
            difficulty: .medium,
            grid: ["EASEL", "#BUY#", "LIPID", "#DEN#", "MERGE"],
            acrossClues: [1: "Painter's stand", 5: "Purchase", 6: "Fat or oil, biologically", 7: "Cozy home room, or a lion's lair", 8: "Combine into one"],
            downClues: [2: "Tolerate or put up with", 3: "Excellent; a building manager", 4: "Watching closely"]
        ),
        Puzzle(
            id: "px-021",
            title: "Morning Mini",
            difficulty: .easy,
            grid: ["DOG##", "APART", "TAMER", "ELUDE", "##TOE"],
            acrossClues: [1: "Loyal canine pet", 4: "Separated", 7: "More docile; a circus trainer", 8: "Escape from cleverly", 9: "Foot digit"],
            downClues: [1: "Calendar day, or a romantic outing", 2: "Iridescent gemstone", 3: "Full range, from A to Z", 5: "Do over again", 6: "Tall woody plant"]
        ),
        Puzzle(
            id: "px-022",
            title: "Coffee Break",
            difficulty: .easy,
            grid: ["##DUB", "CHOSE", "LAPEL", "ALERT", "PLY##"],
            acrossClues: [1: "Give a nickname to", 4: "Picked, in the past", 6: "Folded collar of a jacket", 7: "On guard; a warning notice", 8: "Layer of yarn or wood; to work at"],
            downClues: [1: "Groggy or dim-witted", 2: "One who operates something", 3: "Waist accessory with a buckle", 4: "Applaud", 5: "Corridor or large room"]
        ),
        Puzzle(
            id: "px-023",
            title: "Quick Six",
            difficulty: .medium,
            grid: ["SLANG", "LOWER", "AWARE", "NERVE", "GREET"],
            acrossClues: [1: "Informal vocabulary", 6: "Drop down; more beneath", 7: "Conscious of; informed", 8: "Body's signal carrier; boldness", 9: "Welcome with a hello"],
            downClues: [1: "Informal vocabulary", 2: "Drop down; more beneath", 3: "Conscious of; informed", 4: "Body's signal carrier; boldness", 5: "Welcome with a hello"]
        ),
        Puzzle(
            id: "px-024",
            title: "Lunchtime",
            difficulty: .medium,
            grid: ["SNIFF", "NAVAL", "IVORY", "FARCE", "FLYER"],
            acrossClues: [1: "Inhale through the nose", 6: "Relating to a navy", 7: "Elephant tusk material; piano key color", 8: "Absurd comedy or sham", 9: "Promotional leaflet"],
            downClues: [1: "Inhale through the nose", 2: "Relating to a navy", 3: "Elephant tusk material; piano key color", 4: "Absurd comedy or sham", 5: "Promotional leaflet"]
        ),
        Puzzle(
            id: "px-025",
            title: "Tea Time",
            difficulty: .medium,
            grid: ["QUACK", "URBAN", "ABOVE", "CAVIL", "KNELL"],
            acrossClues: [1: "Duck's sound; a fake doctor", 6: "Of the city", 7: "Higher than", 8: "Raise petty objections", 9: "Slow funeral bell sound"],
            downClues: [1: "Duck's sound; a fake doctor", 2: "Of the city", 3: "Higher than", 4: "Raise petty objections", 5: "Slow funeral bell sound"]
        ),
        Puzzle(
            id: "px-026",
            title: "Brain Teaser",
            difficulty: .hard,
            grid: ["LIMBO", "ILIAC", "MIDST", "BASTE", "OCTET"],
            acrossClues: [1: "Dance under a bar; an in-between state", 6: "Of the hip bone", 7: "In the middle of", 8: "Moisten a roast with juices", 9: "Group of eight"],
            downClues: [1: "Dance under a bar; an in-between state", 2: "Of the hip bone", 3: "In the middle of", 4: "Moisten a roast with juices", 5: "Group of eight"]
        ),
        Puzzle(
            id: "px-027",
            title: "Sunset Mini",
            difficulty: .easy,
            grid: ["EYED#", "YODEL", "EDIFY", "DEFER", "#LYRE"],
            acrossClues: [1: "Looked at closely", 5: "Alpine warbling song", 7: "Instruct and improve morally", 8: "Postpone", 9: "Small ancient harp"],
            downClues: [1: "Looked at closely", 2: "Alpine warbling song", 3: "Instruct and improve morally", 4: "Postpone", 6: "Small ancient harp"]
        ),
        Puzzle(
            id: "px-028",
            title: "Nightcap",
            difficulty: .easy,
            grid: ["#HOPE", "PEARL", "OASIS", "OVINE", "LEST#"],
            acrossClues: [1: "Wish for with confidence", 5: "Gem formed inside an oyster", 6: "Green spot in a desert", 7: "Of or like sheep", 8: "For fear that"],
            downClues: [1: "Lift with effort", 2: "Green spot in a desert", 3: "Make a copy on paper", 4: "Otherwise; in addition", 5: "Swimming spot, or to combine"]
        ),
        Puzzle(
            id: "px-029",
            title: "Crosstown",
            difficulty: .medium,
            grid: ["#PATH", "RADII", "#DOT#", "URBAN", "SEEN#"],
            acrossClues: [1: "Walking trail", 5: "Plural of radius", 6: "Small round mark", 7: "Of the city", 8: "Viewed"],
            downClues: [1: "A military chaplain", 2: "Sun-dried clay brick", 3: "A giant; a moon of Saturn", 4: "Casual greeting", 7: "You and me"]
        ),
        Puzzle(
            id: "px-030",
            title: "Late Edition",
            difficulty: .hard,
            grid: ["CHAOS", "HAUNT", "AUDIO", "ONION", "STONY"],
            acrossClues: [1: "Complete disorder", 6: "Place often visited; to spook", 7: "Sound portion of a broadcast", 8: "Layered, tear-inducing bulb", 9: "Hard like rock; unfeeling"],
            downClues: [1: "Complete disorder", 2: "Place often visited; to spook", 3: "Sound portion of a broadcast", 4: "Layered, tear-inducing bulb", 5: "Hard like rock; unfeeling"]
        ),
        Puzzle(
            id: "px-031",
            title: "Midi: Picture Frame",
            difficulty: .hard,
            grid: ["##CAD##", "#WIRED#", "CIRCLES", "ARCHIVE", "DELIMIT", "#DEVIL#", "##SET##"],
            acrossClues: [1: "An ungentlemanly man", 4: "Connected up; jittery from caffeine", 6: "Round shapes; goes around", 8: "Collection of historical records", 9: "Set the boundaries of", 10: "The fiend himself", 11: "A matching group; to place"],
            downClues: [1: "Round shapes; goes around", 2: "Collection of historical records", 3: "Set the boundaries of", 4: "Connected up; jittery from caffeine", 5: "The fiend himself", 6: "An ungentlemanly man", 7: "A matching group; to place"]
        ),
        Puzzle(
            id: "px-032",
            title: "Midi: Staircase",
            difficulty: .hard,
            grid: ["###ART#", "##FLEA#", "#SALAMI", "ALLUDES", "SOLDER#", "#PEER##", "#END###"],
            acrossClues: [1: "Painting and sculpture, e.g.", 4: "Tiny jumping pest", 5: "Cured Italian sausage", 7: "Hints at, with 'to'", 8: "Metal used to join wires", 9: "An equal; to look closely", 10: "Conclusion"],
            downClues: [1: "Made an indirect reference", 2: "One who peruses books", 3: "More docile; a circus trainer", 4: "Dropped to the ground", 5: "An incline", 6: "Exists, third-person", 7: "While; in the role of"]
        ),
        Puzzle(
            id: "px-033",
            title: "Midi: Pillars",
            difficulty: .hard,
            grid: ["E#ACE#T", "R#RAM#R", "ABILITY", "##DON##", "FAIREST", "A#TIN#A", "T#YET#B"],
            acrossClues: [2: "Tennis serve winner, or a top pilot", 6: "Male sheep; to crash into", 7: "Skill or talent", 8: "Put on, as a coat", 9: "Most just, or most beautiful", 11: "Can metal", 12: "Up to now; nevertheless"],
            downClues: [1: "Historical period", 2: "Extreme dryness", 3: "Unit of food energy", 4: "Famous and respected", 5: "Make an attempt", 9: "Greasy substance; plump", 10: "Bar bill; a keyboard key"]
        ),
    ]

    /// Look up a puzzle by id.
    static func puzzle(id: String) -> Puzzle? {
        all.first { $0.id == id }
    }

    /// The daily puzzle for a given date, chosen deterministically so everyone
    /// gets the same puzzle on the same day, cycling through the bank.
    static func daily(for date: Date = .now) -> Puzzle {
        guard !all.isEmpty else {
            return Puzzle(id: "empty", title: "No puzzle", difficulty: .easy, grid: ["A"], acrossClues: [:], downClues: [:])
        }
        let index = DateKey.dayNumber(for: date) % all.count
        return all[index]
    }

    /// The id of the daily puzzle for a date.
    static func dailyID(for date: Date = .now) -> String { daily(for: date).id }
}
