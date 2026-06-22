import Foundation

struct WordPack: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let description: String
    let words: [String]
    let isPro: Bool

    var wordCount: Int { words.count }
}

struct WordPackLibrary {
    static let allPacks: [WordPack] = [animals, moviesTV, foodCooking, sportsActivities, everydayLife]

    static let animals = WordPack(
        id: "animals",
        name: "Animals",
        emoji: "🐾",
        description: "From the familiar to the wonderfully weird",
        words: [
            "elephant", "flamingo", "porcupine", "octopus", "giraffe",
            "penguin", "sloth", "jellyfish", "peacock", "chameleon",
            "platypus", "walrus", "hedgehog", "koala", "capybara",
            "axolotl", "narwhal", "manta ray", "okapi", "wombat",
            "anteater", "secretary bird", "thorny devil", "pangolin", "blobfish",
            "quokka", "tapir", "binturong", "aye-aye", "fossa",
            "saiga antelope", "dugong", "hoopoe", "kinkajou", "mudskipper",
            "mandrill", "shoebill", "proboscis monkey", "star-nosed mole", "manatee"
        ],
        isPro: false
    )

    static let moviesTV = WordPack(
        id: "movies-tv",
        name: "Movies & TV",
        emoji: "🎬",
        description: "Hollywood terms and cinematic concepts",
        words: [
            "spaceship", "villain", "plot twist", "cliffhanger", "animation",
            "stuntman", "sequel", "trailer", "blooper", "premiere",
            "subtitle", "documentary", "intermission", "cameo", "director",
            "flashback", "montage", "franchise", "reboot", "pilot episode",
            "finale", "credits", "soundtrack", "casting", "screenplay",
            "storyboard", "close-up", "dramatic irony", "foreshadowing", "ensemble cast",
            "blockbuster", "indie film", "film noir", "mockumentary", "spin-off",
            "anthology", "miniseries", "crossover", "binge-watching", "title card"
        ],
        isPro: true
    )

    static let foodCooking = WordPack(
        id: "food-cooking",
        name: "Food & Cooking",
        emoji: "🍳",
        description: "Dishes and ingredients from around the world",
        words: [
            "spaghetti", "blender", "waffle", "sushi", "avocado",
            "pretzel", "cinnamon roll", "fondue", "baguette", "tiramisu",
            "churros", "dim sum", "empanada", "falafel", "shawarma",
            "bibimbap", "baklava", "crepe", "macaron", "tempura",
            "yakitori", "udon", "pad thai", "pho", "croissant",
            "paella", "gazpacho", "risotto", "bruschetta", "gyoza",
            "tzatziki", "cassoulet", "bouillabaisse", "ratatouille", "feijoada",
            "pierogi", "goulash", "tagine", "mochi", "sourdough"
        ],
        isPro: true
    )

    static let sportsActivities = WordPack(
        id: "sports-activities",
        name: "Sports & Activities",
        emoji: "⚡",
        description: "Olympic sports and athletic feats",
        words: [
            "skateboard", "surfboard", "somersault", "handstand", "pole vault",
            "synchronized swimming", "curling", "archery", "fencing", "bobsled",
            "luge", "discus throw", "javelin", "hammer throw", "shot put",
            "pentathlon", "decathlon", "steeplechase", "hurdles", "relay race",
            "high jump", "triple jump", "long jump", "parallel bars", "pommel horse",
            "floor exercise", "vault gymnastics", "uneven bars", "balance beam", "trampoline",
            "rhythmic gymnastics", "aerobics", "cross-country skiing", "biathlon", "skeleton",
            "speed skating", "figure skating", "ice hockey", "water polo", "rowing"
        ],
        isPro: false
    )

    static let everydayLife = WordPack(
        id: "everyday-life",
        name: "Everyday Life",
        emoji: "🏠",
        description: "Objects and gadgets from daily life",
        words: [
            "umbrella", "elevator", "escalator", "telescope", "microscope",
            "thermometer", "compass", "calculator", "typewriter", "gramophone",
            "periscope", "kaleidoscope", "metronome", "pendulum", "boomerang",
            "yo-yo", "pinwheel", "sundial", "abacus", "astrolabe",
            "slide rule", "magnifying glass", "bubble wrap", "zip tie", "paper clip",
            "stapler", "hole punch", "rubber band", "push pin", "paper bag",
            "recycling bin", "compost", "thermos", "lunchbox", "briefcase",
            "satchel", "duffel bag", "rolling suitcase", "fanny pack", "tote bag"
        ],
        isPro: false
    )

    static func pack(for id: String) -> WordPack? {
        allPacks.first { $0.id == id }
    }

    static func words(for packId: String) -> [String] {
        pack(for: packId)?.words ?? animals.words
    }

    // Free packs available without Pro
    static let freePackIds: Set<String> = ["animals", "everyday-life", "sports-activities"]
}
