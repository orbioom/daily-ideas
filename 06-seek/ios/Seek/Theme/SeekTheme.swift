import SwiftUI

enum SeekTheme {
    static let background = Color(red: 0.05, green: 0.08, blue: 0.12)
    static let surface = Color(red: 0.10, green: 0.14, blue: 0.20)
    static let cellBackground = Color(red: 0.12, green: 0.17, blue: 0.24)
    static let accent = Color(red: 0.25, green: 0.75, blue: 0.95)
    static let accentGold = Color(red: 0.98, green: 0.82, blue: 0.25)
    static let textPrimary = Color(red: 0.92, green: 0.95, blue: 0.98)
    static let textSecondary = Color(red: 0.50, green: 0.58, blue: 0.68)
    static let foundColor = Color(red: 0.25, green: 0.85, blue: 0.55)
    static let selectionColor = Color(red: 0.25, green: 0.75, blue: 0.95)
    static let highlightColors: [Color] = [
        Color(red: 0.25, green: 0.85, blue: 0.55),
        Color(red: 0.25, green: 0.65, blue: 0.95),
        Color(red: 0.95, green: 0.75, blue: 0.25),
        Color(red: 0.85, green: 0.35, blue: 0.85),
        Color(red: 0.95, green: 0.50, blue: 0.25),
        Color(red: 0.55, green: 0.35, blue: 0.95),
    ]
}

enum PuzzleDifficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var gridSize: Int {
        switch self {
        case .easy: return 10
        case .medium: return 13
        case .hard: return 15
        }
    }

    var wordCount: Int {
        switch self {
        case .easy: return 8
        case .medium: return 12
        case .hard: return 16
        }
    }
}

struct WordCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let words: [String]

    static let all: [WordCategory] = [
        WordCategory(name: "Animals", icon: "pawprint.fill", words: [
            "LION", "TIGER", "BEAR", "WOLF", "EAGLE", "SHARK", "WHALE", "ELEPHANT", "GIRAFFE",
            "DOLPHIN", "PENGUIN", "CHEETAH", "GORILLA", "PANTHER", "LEOPARD", "JAGUAR", "FALCON",
            "COBRA", "PYTHON", "CONDOR", "BUFFALO", "CARIBOU", "MOOSE", "BEAVER", "OTTER"
        ]),
        WordCategory(name: "Space", icon: "star.fill", words: [
            "GALAXY", "NEBULA", "PLANET", "METEOR", "COMET", "ORBIT", "SATURN", "JUPITER",
            "MARS", "VENUS", "PLUTO", "PULSAR", "QUASAR", "COSMOS", "AURORA", "ECLIPSE",
            "SOLSTICE", "EQUINOX", "CRATER", "ZENITH", "PHOTON", "PROTON", "NEUTRON", "NUCLEUS"
        ]),
        WordCategory(name: "Countries", icon: "globe.americas.fill", words: [
            "BRAZIL", "CANADA", "FRANCE", "GERMANY", "INDIA", "JAPAN", "MEXICO", "RUSSIA",
            "CHINA", "ITALY", "SPAIN", "EGYPT", "KENYA", "GHANA", "PERU", "CHILE",
            "GREECE", "TURKEY", "SWEDEN", "NORWAY", "POLAND", "UKRAINE", "AUSTRIA", "BELGIUM"
        ]),
        WordCategory(name: "Sports", icon: "sportscourt.fill", words: [
            "SOCCER", "TENNIS", "BOXING", "SKIING", "ROWING", "CYCLING", "SURFING", "ARCHERY",
            "FENCING", "JUDO", "KARATE", "RUGBY", "HOCKEY", "CRICKET", "GOLF", "POLO",
            "SQUASH", "BADMINTON", "VOLLEYBALL", "BASKETBALL", "BASEBALL", "SOFTBALL", "LACROSSE"
        ]),
        WordCategory(name: "Science", icon: "atom", words: [
            "ATOM", "CELL", "GENE", "LASER", "RADAR", "SONAR", "VIRUS", "FUNGI", "ALGAE",
            "OXYGEN", "CARBON", "HELIUM", "NEON", "SODIUM", "CALCIUM", "SILICON", "NITROGEN",
            "PLASMA", "ENZYME", "PROTEIN", "GLUCOSE", "NUCLEUS", "ELECTRON", "PROTON", "QUANTUM"
        ]),
        WordCategory(name: "Foods", icon: "fork.knife", words: [
            "PIZZA", "SUSHI", "TACOS", "PASTA", "CURRY", "RAMEN", "BAGEL", "WAFFLE", "MUFFIN",
            "CREPE", "FALAFEL", "HUMMUS", "PITA", "KEBAB", "RISOTTO", "PAELLA", "GYROS",
            "KIMCHI", "TEMPURA", "TIRAMISU", "CROISSANT", "LASAGNA", "BURRITO", "EMPANADA"
        ]),
        WordCategory(name: "Music", icon: "music.note", words: [
            "GUITAR", "PIANO", "VIOLIN", "DRUMS", "FLUTE", "CELLO", "OBOE", "HARP", "LUTE",
            "BANJO", "TRUMPET", "TROMBONE", "CLARINET", "BASSOON", "ACCORDION", "SAXOPHONE",
            "HARMONICA", "MANDOLIN", "UKULELE", "XYLOPHONE", "MARIMBA", "SITAR", "DIDGERIDOO"
        ]),
        WordCategory(name: "Ocean", icon: "water.waves", words: [
            "CORAL", "REEF", "KELP", "TIDE", "WAVE", "SHORE", "DEPTH", "ABYSS", "TRENCH",
            "CURRENT", "PLANKTON", "SEAHORSE", "STARFISH", "JELLYFISH", "OCTOPUS", "SQUID",
            "LOBSTER", "CRAB", "SHRIMP", "ANCHOVY", "TUNA", "SALMON", "SWORDFISH", "BARRACUDA"
        ]),
    ]
}
