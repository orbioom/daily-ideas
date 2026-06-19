import Foundation

enum Difficulty: String, Codable, CaseIterable {
    case easy, medium, hard
    var label: String { rawValue.capitalized }
    var letterCount: ClosedRange<Int> {
        switch self { case .easy: return 4...5; case .medium: return 6...7; case .hard: return 8...10 }
    }
}

enum WordCategory: String, Codable, CaseIterable {
    case animals, food, nature, sports, cities, science, music, movies
    var label: String { rawValue.capitalized }
    var emoji: String {
        switch self {
        case .animals: return "🐾"
        case .food: return "🍕"
        case .nature: return "🌿"
        case .sports: return "⚽"
        case .cities: return "🏙️"
        case .science: return "🔬"
        case .music: return "🎵"
        case .movies: return "🎬"
        }
    }
}

struct WordEntry: Identifiable {
    let id = UUID()
    let word: String
    let category: WordCategory
    let difficulty: Difficulty
    let hint: String
}

struct WordDatabase {
    static let all: [WordEntry] = animals + food + nature + sports + cities + science + music + movies

    // MARK: - Animals (~80 words)
    static let animals: [WordEntry] = [
        WordEntry(word: "LION", category: .animals, difficulty: .easy, hint: "King of the jungle"),
        WordEntry(word: "WOLF", category: .animals, difficulty: .easy, hint: "Howls at the moon"),
        WordEntry(word: "BEAR", category: .animals, difficulty: .easy, hint: "Hibernates in winter"),
        WordEntry(word: "DUCK", category: .animals, difficulty: .easy, hint: "Quacks loudly"),
        WordEntry(word: "FROG", category: .animals, difficulty: .easy, hint: "Jumps on lily pads"),
        WordEntry(word: "CROW", category: .animals, difficulty: .easy, hint: "Intelligent black bird"),
        WordEntry(word: "MOLE", category: .animals, difficulty: .easy, hint: "Digs underground tunnels"),
        WordEntry(word: "LYNX", category: .animals, difficulty: .easy, hint: "Wild spotted cat"),
        WordEntry(word: "EAGLE", category: .animals, difficulty: .easy, hint: "National bird of USA"),
        WordEntry(word: "SHARK", category: .animals, difficulty: .easy, hint: "Ocean's apex predator"),
        WordEntry(word: "RHINO", category: .animals, difficulty: .easy, hint: "Has a horn on its nose"),
        WordEntry(word: "PANDA", category: .animals, difficulty: .easy, hint: "Black and white bear from China"),
        WordEntry(word: "KOALA", category: .animals, difficulty: .easy, hint: "Australian marsupial"),
        WordEntry(word: "OTTER", category: .animals, difficulty: .easy, hint: "Floats on its back"),
        WordEntry(word: "BISON", category: .animals, difficulty: .easy, hint: "American buffalo"),
        WordEntry(word: "GECKO", category: .animals, difficulty: .easy, hint: "Small tropical lizard"),
        WordEntry(word: "VIPER", category: .animals, difficulty: .easy, hint: "Venomous snake"),
        WordEntry(word: "HYENA", category: .animals, difficulty: .easy, hint: "Laughing scavenger"),
        WordEntry(word: "TAPIR", category: .animals, difficulty: .easy, hint: "South American mammal with a snout"),
        WordEntry(word: "MOOSE", category: .animals, difficulty: .easy, hint: "Largest deer species"),
        WordEntry(word: "FALCON", category: .animals, difficulty: .medium, hint: "Fastest bird"),
        WordEntry(word: "JAGUAR", category: .animals, difficulty: .medium, hint: "Spotted big cat"),
        WordEntry(word: "WALRUS", category: .animals, difficulty: .medium, hint: "Arctic animal with tusks"),
        WordEntry(word: "PARROT", category: .animals, difficulty: .medium, hint: "Mimics human speech"),
        WordEntry(word: "CONDOR", category: .animals, difficulty: .medium, hint: "Largest flying bird"),
        WordEntry(word: "COYOTE", category: .animals, difficulty: .medium, hint: "North American wild dog"),
        WordEntry(word: "TOUCAN", category: .animals, difficulty: .medium, hint: "Tropical bird with big beak"),
        WordEntry(word: "BADGER", category: .animals, difficulty: .medium, hint: "Black and white burrower"),
        WordEntry(word: "IGUANA", category: .animals, difficulty: .medium, hint: "Large green lizard"),
        WordEntry(word: "WOMBAT", category: .animals, difficulty: .medium, hint: "Australian marsupial"),
        WordEntry(word: "OSTRICH", category: .animals, difficulty: .medium, hint: "Largest bird, cannot fly"),
        WordEntry(word: "PLATYPUS", category: .animals, difficulty: .hard, hint: "Egg-laying mammal"),
        WordEntry(word: "SCORPION", category: .animals, difficulty: .hard, hint: "Has a stinging tail"),
        WordEntry(word: "PANGOLIN", category: .animals, difficulty: .hard, hint: "Scaly anteater"),
        WordEntry(word: "MONGOOSE", category: .animals, difficulty: .hard, hint: "Fights cobras"),
        WordEntry(word: "FLAMINGO", category: .animals, difficulty: .hard, hint: "Pink bird stands on one leg"),
        WordEntry(word: "PORPOISE", category: .animals, difficulty: .hard, hint: "Small dolphin relative"),
        WordEntry(word: "ANTELOPE", category: .animals, difficulty: .hard, hint: "African grazing animal"),
        WordEntry(word: "ALBATROSS", category: .animals, difficulty: .hard, hint: "Seabird with huge wingspan"),
        WordEntry(word: "CHAMELEON", category: .animals, difficulty: .hard, hint: "Changes color to camouflage"),
    ]

    // MARK: - Food (~70 words)
    static let food: [WordEntry] = [
        WordEntry(word: "TACO", category: .food, difficulty: .easy, hint: "Mexican folded tortilla"),
        WordEntry(word: "RICE", category: .food, difficulty: .easy, hint: "Asian staple grain"),
        WordEntry(word: "SOUP", category: .food, difficulty: .easy, hint: "Hot liquid dish"),
        WordEntry(word: "CAKE", category: .food, difficulty: .easy, hint: "Birthday tradition"),
        WordEntry(word: "PEAR", category: .food, difficulty: .easy, hint: "Teardrop-shaped fruit"),
        WordEntry(word: "PLUM", category: .food, difficulty: .easy, hint: "Purple stone fruit"),
        WordEntry(word: "KIWI", category: .food, difficulty: .easy, hint: "Fuzzy green fruit"),
        WordEntry(word: "BEET", category: .food, difficulty: .easy, hint: "Deep red root vegetable"),
        WordEntry(word: "LEEK", category: .food, difficulty: .easy, hint: "Mild onion relative"),
        WordEntry(word: "TOFU", category: .food, difficulty: .easy, hint: "Soy-based protein"),
        WordEntry(word: "PASTA", category: .food, difficulty: .easy, hint: "Italian noodle dish"),
        WordEntry(word: "PIZZA", category: .food, difficulty: .easy, hint: "Italian flat bread with toppings"),
        WordEntry(word: "MANGO", category: .food, difficulty: .easy, hint: "Tropical yellow-red fruit"),
        WordEntry(word: "OLIVE", category: .food, difficulty: .easy, hint: "Mediterranean fruit"),
        WordEntry(word: "PEACH", category: .food, difficulty: .easy, hint: "Fuzzy summer fruit"),
        WordEntry(word: "BASIL", category: .food, difficulty: .easy, hint: "Italian herb for pesto"),
        WordEntry(word: "ONION", category: .food, difficulty: .easy, hint: "Makes you cry when chopped"),
        WordEntry(word: "LEMON", category: .food, difficulty: .easy, hint: "Sour yellow citrus"),
        WordEntry(word: "CREPE", category: .food, difficulty: .easy, hint: "Thin French pancake"),
        WordEntry(word: "BAGEL", category: .food, difficulty: .easy, hint: "Round bread with a hole"),
        WordEntry(word: "QUICHE", category: .food, difficulty: .medium, hint: "French egg tart"),
        WordEntry(word: "MUFFIN", category: .food, difficulty: .medium, hint: "Single-serve baked good"),
        WordEntry(word: "WALNUT", category: .food, difficulty: .medium, hint: "Brain-shaped tree nut"),
        WordEntry(word: "RADISH", category: .food, difficulty: .medium, hint: "Spicy red root vegetable"),
        WordEntry(word: "CASHEW", category: .food, difficulty: .medium, hint: "Curved tree nut"),
        WordEntry(word: "CHERRY", category: .food, difficulty: .medium, hint: "Small red stone fruit"),
        WordEntry(word: "GINGER", category: .food, difficulty: .medium, hint: "Spicy root used in cooking"),
        WordEntry(word: "FENNEL", category: .food, difficulty: .medium, hint: "Licorice-flavored vegetable"),
        WordEntry(word: "PAPAYA", category: .food, difficulty: .medium, hint: "Orange tropical fruit"),
        WordEntry(word: "WAFFLE", category: .food, difficulty: .medium, hint: "Grid-patterned breakfast"),
        WordEntry(word: "BURRITO", category: .food, difficulty: .medium, hint: "Wrapped Mexican meal"),
        WordEntry(word: "AVOCADO", category: .food, difficulty: .medium, hint: "Creamy green fruit for guacamole"),
        WordEntry(word: "LOBSTER", category: .food, difficulty: .medium, hint: "Red when cooked seafood"),
        WordEntry(word: "APRICOT", category: .food, difficulty: .medium, hint: "Small orange stone fruit"),
        WordEntry(word: "BROCCOLI", category: .food, difficulty: .hard, hint: "Green tree-like vegetable"),
        WordEntry(word: "CINNAMON", category: .food, difficulty: .hard, hint: "Sweet brown spice"),
        WordEntry(word: "EGGPLANT", category: .food, difficulty: .hard, hint: "Purple Italian vegetable"),
        WordEntry(word: "BLUEBERRY", category: .food, difficulty: .hard, hint: "Small blue antioxidant berry"),
        WordEntry(word: "ARTICHOKE", category: .food, difficulty: .hard, hint: "Edible flower bud vegetable"),
        WordEntry(word: "RASPBERRY", category: .food, difficulty: .hard, hint: "Red cluster berry"),
    ]

    // MARK: - Nature (~60 words)
    static let nature: [WordEntry] = [
        WordEntry(word: "LAKE", category: .nature, difficulty: .easy, hint: "Body of inland water"),
        WordEntry(word: "CAVE", category: .nature, difficulty: .easy, hint: "Underground hollow"),
        WordEntry(word: "REEF", category: .nature, difficulty: .easy, hint: "Coral structure in ocean"),
        WordEntry(word: "DUNE", category: .nature, difficulty: .easy, hint: "Sand hill in desert"),
        WordEntry(word: "GUST", category: .nature, difficulty: .easy, hint: "Sudden burst of wind"),
        WordEntry(word: "MIST", category: .nature, difficulty: .easy, hint: "Light fog or spray"),
        WordEntry(word: "TIDE", category: .nature, difficulty: .easy, hint: "Ocean's rise and fall"),
        WordEntry(word: "DAWN", category: .nature, difficulty: .easy, hint: "First light of day"),
        WordEntry(word: "PEAK", category: .nature, difficulty: .easy, hint: "Mountain summit"),
        WordEntry(word: "MARSH", category: .nature, difficulty: .easy, hint: "Wetland ecosystem"),
        WordEntry(word: "FJORD", category: .nature, difficulty: .easy, hint: "Norwegian coastal inlet"),
        WordEntry(word: "DELTA", category: .nature, difficulty: .easy, hint: "River mouth region"),
        WordEntry(word: "GEYSER", category: .nature, difficulty: .medium, hint: "Natural hot water spout"),
        WordEntry(word: "CANYON", category: .nature, difficulty: .medium, hint: "Deep rocky gorge"),
        WordEntry(word: "TUNDRA", category: .nature, difficulty: .medium, hint: "Arctic treeless plain"),
        WordEntry(word: "LAGOON", category: .nature, difficulty: .medium, hint: "Shallow coastal lake"),
        WordEntry(word: "RAVINE", category: .nature, difficulty: .medium, hint: "Narrow steep-sided valley"),
        WordEntry(word: "TAIGA", category: .nature, difficulty: .medium, hint: "Boreal conifer forest"),
        WordEntry(word: "STEPPE", category: .nature, difficulty: .medium, hint: "Dry grassland plain"),
        WordEntry(word: "MANGROVE", category: .nature, difficulty: .hard, hint: "Coastal tropical tree"),
        WordEntry(word: "CREVASSE", category: .nature, difficulty: .hard, hint: "Deep glacier crack"),
        WordEntry(word: "SAVANNA", category: .nature, difficulty: .hard, hint: "African grassland with trees"),
        WordEntry(word: "ESTUARY", category: .nature, difficulty: .hard, hint: "Tidal river mouth"),
        WordEntry(word: "SOLSTICE", category: .nature, difficulty: .hard, hint: "Longest or shortest day"),
        WordEntry(word: "STALACTITE", category: .nature, difficulty: .hard, hint: "Mineral formation hanging from cave"),
    ]

    // MARK: - Sports (~50 words)
    static let sports: [WordEntry] = [
        WordEntry(word: "GOLF", category: .sports, difficulty: .easy, hint: "Hit ball into hole"),
        WordEntry(word: "POLO", category: .sports, difficulty: .easy, hint: "Played on horseback"),
        WordEntry(word: "LUGE", category: .sports, difficulty: .easy, hint: "Feet-first ice sliding"),
        WordEntry(word: "JUDO", category: .sports, difficulty: .easy, hint: "Japanese throwing martial art"),
        WordEntry(word: "SWIM", category: .sports, difficulty: .easy, hint: "Move through water"),
        WordEntry(word: "RUGBY", category: .sports, difficulty: .easy, hint: "Oval ball, no pads"),
        WordEntry(word: "SQUASH", category: .sports, difficulty: .medium, hint: "Racket sport in enclosed court"),
        WordEntry(word: "FENCING", category: .sports, difficulty: .medium, hint: "Sword sport"),
        WordEntry(word: "CURLING", category: .sports, difficulty: .medium, hint: "Ice stone sweeping sport"),
        WordEntry(word: "ROWING", category: .sports, difficulty: .medium, hint: "Team boat racing"),
        WordEntry(word: "KARATE", category: .sports, difficulty: .medium, hint: "Japanese striking martial art"),
        WordEntry(word: "SPRINT", category: .sports, difficulty: .medium, hint: "Short-distance running race"),
        WordEntry(word: "ARCHERY", category: .sports, difficulty: .medium, hint: "Bow and arrow sport"),
        WordEntry(word: "TRIATHLON", category: .sports, difficulty: .hard, hint: "Swim, bike, run race"),
        WordEntry(word: "DECATHLON", category: .sports, difficulty: .hard, hint: "Ten-event Olympic contest"),
        WordEntry(word: "BIATHLON", category: .sports, difficulty: .hard, hint: "Skiing and shooting"),
        WordEntry(word: "PENTATHLON", category: .sports, difficulty: .hard, hint: "Five-event Olympic sport"),
        WordEntry(word: "BOBSLED", category: .sports, difficulty: .hard, hint: "Team ice racing sled"),
        WordEntry(word: "HANDBALL", category: .sports, difficulty: .hard, hint: "Team goal sport with hands"),
        WordEntry(word: "LACROSSE", category: .sports, difficulty: .hard, hint: "Net-stick ball sport"),
    ]

    // MARK: - Cities (~50 words)
    static let cities: [WordEntry] = [
        WordEntry(word: "ROME", category: .cities, difficulty: .easy, hint: "Eternal City in Italy"),
        WordEntry(word: "LIMA", category: .cities, difficulty: .easy, hint: "Capital of Peru"),
        WordEntry(word: "OSLO", category: .cities, difficulty: .easy, hint: "Capital of Norway"),
        WordEntry(word: "KYIV", category: .cities, difficulty: .easy, hint: "Capital of Ukraine"),
        WordEntry(word: "DUBAI", category: .cities, difficulty: .easy, hint: "City of skyscrapers in UAE"),
        WordEntry(word: "CAIRO", category: .cities, difficulty: .easy, hint: "City near the pyramids"),
        WordEntry(word: "PARIS", category: .cities, difficulty: .easy, hint: "City of Love and Eiffel Tower"),
        WordEntry(word: "SEOUL", category: .cities, difficulty: .easy, hint: "Capital of South Korea"),
        WordEntry(word: "TOKYO", category: .cities, difficulty: .easy, hint: "Largest city in Japan"),
        WordEntry(word: "DELHI", category: .cities, difficulty: .easy, hint: "Capital territory of India"),
        WordEntry(word: "BERLIN", category: .cities, difficulty: .medium, hint: "Capital of Germany"),
        WordEntry(word: "LISBON", category: .cities, difficulty: .medium, hint: "Capital of Portugal"),
        WordEntry(word: "MANILA", category: .cities, difficulty: .medium, hint: "Capital of Philippines"),
        WordEntry(word: "NAIROBI", category: .cities, difficulty: .medium, hint: "Capital of Kenya"),
        WordEntry(word: "TORONTO", category: .cities, difficulty: .medium, hint: "Largest city in Canada"),
        WordEntry(word: "JAKARTA", category: .cities, difficulty: .medium, hint: "Former capital of Indonesia"),
        WordEntry(word: "CHICAGO", category: .cities, difficulty: .medium, hint: "Windy City on Lake Michigan"),
        WordEntry(word: "BANGKOK", category: .cities, difficulty: .medium, hint: "Capital of Thailand"),
        WordEntry(word: "MONTREAL", category: .cities, difficulty: .hard, hint: "French-speaking Canadian city"),
        WordEntry(word: "SINGAPORE", category: .cities, difficulty: .hard, hint: "City-state in Southeast Asia"),
        WordEntry(word: "STOCKHOLM", category: .cities, difficulty: .hard, hint: "Capital of Sweden"),
        WordEntry(word: "AMSTERDAM", category: .cities, difficulty: .hard, hint: "Canal city in Netherlands"),
        WordEntry(word: "BARCELONA", category: .cities, difficulty: .hard, hint: "Gaudi's city in Spain"),
        WordEntry(word: "REYKJAVIK", category: .cities, difficulty: .hard, hint: "Capital of Iceland"),
        WordEntry(word: "WELLINGTON", category: .cities, difficulty: .hard, hint: "Capital of New Zealand"),
    ]

    // MARK: - Science (~50 words)
    static let science: [WordEntry] = [
        WordEntry(word: "ATOM", category: .science, difficulty: .easy, hint: "Smallest unit of matter"),
        WordEntry(word: "GENE", category: .science, difficulty: .easy, hint: "Unit of heredity"),
        WordEntry(word: "LENS", category: .science, difficulty: .easy, hint: "Refracts light in optics"),
        WordEntry(word: "VOLT", category: .science, difficulty: .easy, hint: "Unit of electrical potential"),
        WordEntry(word: "CELL", category: .science, difficulty: .easy, hint: "Basic unit of life"),
        WordEntry(word: "LASER", category: .science, difficulty: .easy, hint: "Focused light beam"),
        WordEntry(word: "ORBIT", category: .science, difficulty: .easy, hint: "Path around a planet"),
        WordEntry(word: "PRISM", category: .science, difficulty: .easy, hint: "Splits white light into colors"),
        WordEntry(word: "QUARK", category: .science, difficulty: .easy, hint: "Subatomic particle"),
        WordEntry(word: "MAGNET", category: .science, difficulty: .medium, hint: "Attracts iron objects"),
        WordEntry(word: "PLASMA", category: .science, difficulty: .medium, hint: "Fourth state of matter"),
        WordEntry(word: "PROTON", category: .science, difficulty: .medium, hint: "Positive particle in nucleus"),
        WordEntry(word: "NEURON", category: .science, difficulty: .medium, hint: "Brain nerve cell"),
        WordEntry(word: "PHOTON", category: .science, difficulty: .medium, hint: "Particle of light"),
        WordEntry(word: "ENZYME", category: .science, difficulty: .medium, hint: "Biological catalyst"),
        WordEntry(word: "OSMOSIS", category: .science, difficulty: .medium, hint: "Water moving through membrane"),
        WordEntry(word: "NEUTRON", category: .science, difficulty: .medium, hint: "Neutral particle in nucleus"),
        WordEntry(word: "POLYMER", category: .science, difficulty: .medium, hint: "Long chain molecule"),
        WordEntry(word: "ELECTRON", category: .science, difficulty: .hard, hint: "Negative particle orbiting nucleus"),
        WordEntry(word: "MOLECULE", category: .science, difficulty: .hard, hint: "Two or more bonded atoms"),
        WordEntry(word: "ISOTOPE", category: .science, difficulty: .hard, hint: "Variant of same element"),
        WordEntry(word: "CATALYST", category: .science, difficulty: .hard, hint: "Speeds up chemical reactions"),
        WordEntry(word: "GRAVITON", category: .science, difficulty: .hard, hint: "Hypothetical gravity particle"),
        WordEntry(word: "CHLOROPHYLL", category: .science, difficulty: .hard, hint: "Green pigment in plants"),
        WordEntry(word: "CHROMOSOME", category: .science, difficulty: .hard, hint: "DNA-carrying structure"),
    ]

    // MARK: - Music (~40 words)
    static let music: [WordEntry] = [
        WordEntry(word: "BEAT", category: .music, difficulty: .easy, hint: "Rhythm unit in music"),
        WordEntry(word: "BASS", category: .music, difficulty: .easy, hint: "Low-frequency sound"),
        WordEntry(word: "DRUM", category: .music, difficulty: .easy, hint: "Percussion instrument"),
        WordEntry(word: "HARP", category: .music, difficulty: .easy, hint: "Plucked string instrument"),
        WordEntry(word: "LUTE", category: .music, difficulty: .easy, hint: "Medieval plucked instrument"),
        WordEntry(word: "FLUTE", category: .music, difficulty: .easy, hint: "Woodwind blown across hole"),
        WordEntry(word: "CELLO", category: .music, difficulty: .easy, hint: "Large bowed string instrument"),
        WordEntry(word: "TUBA", category: .music, difficulty: .easy, hint: "Largest brass instrument"),
        WordEntry(word: "CHOIR", category: .music, difficulty: .easy, hint: "Group of singers"),
        WordEntry(word: "TEMPO", category: .music, difficulty: .easy, hint: "Speed of music"),
        WordEntry(word: "TREBLE", category: .music, difficulty: .medium, hint: "High musical register"),
        WordEntry(word: "VIOLIN", category: .music, difficulty: .medium, hint: "Small bowed string instrument"),
        WordEntry(word: "SONATA", category: .music, difficulty: .medium, hint: "Classical instrumental composition"),
        WordEntry(word: "OCTAVE", category: .music, difficulty: .medium, hint: "Eight-note musical span"),
        WordEntry(word: "CHORUS", category: .music, difficulty: .medium, hint: "Repeated section of a song"),
        WordEntry(word: "CLARINET", category: .music, difficulty: .hard, hint: "Single-reed woodwind"),
        WordEntry(word: "TROMBONE", category: .music, difficulty: .hard, hint: "Slide brass instrument"),
        WordEntry(word: "SYMPHONY", category: .music, difficulty: .hard, hint: "Large orchestral composition"),
        WordEntry(word: "HARMONICA", category: .music, difficulty: .hard, hint: "Mouth-blown reed instrument"),
        WordEntry(word: "ACCORDION", category: .music, difficulty: .hard, hint: "Bellows-driven keyboard instrument"),
    ]

    // MARK: - Movies (~40 words)
    static let movies: [WordEntry] = [
        WordEntry(word: "PLOT", category: .movies, difficulty: .easy, hint: "Story structure of a film"),
        WordEntry(word: "CAST", category: .movies, difficulty: .easy, hint: "Actors in a movie"),
        WordEntry(word: "REEL", category: .movies, difficulty: .easy, hint: "Film spool"),
        WordEntry(word: "SCENE", category: .movies, difficulty: .easy, hint: "Single continuous film segment"),
        WordEntry(word: "SCORE", category: .movies, difficulty: .easy, hint: "Film's musical soundtrack"),
        WordEntry(word: "GENRE", category: .movies, difficulty: .easy, hint: "Category of film"),
        WordEntry(word: "SEQUEL", category: .movies, difficulty: .medium, hint: "Follow-up film"),
        WordEntry(word: "SCRIPT", category: .movies, difficulty: .medium, hint: "Written movie dialogue"),
        WordEntry(word: "CAMEO", category: .movies, difficulty: .medium, hint: "Brief celebrity appearance"),
        WordEntry(word: "TRAILER", category: .movies, difficulty: .medium, hint: "Preview of upcoming film"),
        WordEntry(word: "STUNTMAN", category: .movies, difficulty: .hard, hint: "Performs dangerous film scenes"),
        WordEntry(word: "DIRECTOR", category: .movies, difficulty: .hard, hint: "Controls film production"),
        WordEntry(word: "PREMIERE", category: .movies, difficulty: .hard, hint: "First showing of a film"),
        WordEntry(word: "FLASHBACK", category: .movies, difficulty: .hard, hint: "Scene from the past"),
        WordEntry(word: "CLIFFHANGER", category: .movies, difficulty: .hard, hint: "Suspenseful ending"),
    ]

    static func dailyWord(for date: Date = Date()) -> WordEntry? {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let seed = UInt64(comps.year! * 10000 + comps.month! * 100 + comps.day!)
        var rng = SplitMix64(seed: seed)
        let idx = rng.nextInt(in: 0..<all.count)
        return all[idx]
    }

    static func words(for category: WordCategory, difficulty: Difficulty? = nil) -> [WordEntry] {
        all.filter { $0.category == category && (difficulty == nil || $0.difficulty == difficulty!) }
    }
}
