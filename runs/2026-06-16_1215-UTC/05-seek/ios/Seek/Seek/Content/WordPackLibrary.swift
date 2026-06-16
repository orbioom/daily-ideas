import Foundation

/// The curated library of themed word packs. All words are UPPERCASE, 3–9 letters, no spaces.
/// The first three packs are free; the remainder require Seek Pro.
enum WordPackLibrary {

    static let all: [WordPack] = [
        WordPack(
            id: "animals", name: "Animals", symbol: "pawprint.fill", tint: 0xE0654E, isPro: false,
            words: ["TIGER", "PANDA", "OTTER", "ZEBRA", "KOALA", "HORSE", "EAGLE", "SHARK",
                    "MOOSE", "CAMEL", "RABBIT", "FALCON", "DONKEY", "BADGER", "WALRUS",
                    "GIRAFFE", "DOLPHIN", "PENGUIN", "LEOPARD", "HAMSTER"]
        ),
        WordPack(
            id: "food", name: "Food & Drink", symbol: "fork.knife", tint: 0xE08A2E, isPro: false,
            words: ["BREAD", "CHEESE", "APPLE", "MANGO", "LEMON", "OLIVE", "PASTA", "SALAD",
                    "COCOA", "JUICE", "BUTTER", "PEPPER", "TOMATO", "BANANA", "WALNUT",
                    "COFFEE", "YOGURT", "BISCUIT", "PANCAKE", "AVOCADO"]
        ),
        WordPack(
            id: "house", name: "Around the House", symbol: "house.fill", tint: 0x4FA773, isPro: false,
            words: ["TABLE", "CHAIR", "LAMP", "SHELF", "CLOCK", "MIRROR", "CARPET", "PILLOW",
                    "WINDOW", "DRAWER", "CANDLE", "BLANKET", "CUSHION", "CURTAIN", "CABINET",
                    "DOORMAT", "TEAPOT", "VASE", "BROOM", "LADDER"]
        ),
        WordPack(
            id: "travel", name: "Travel", symbol: "airplane", tint: 0x3E86C9, isPro: true,
            words: ["BEACH", "HOTEL", "TRAIN", "FLIGHT", "PASSPORT", "LUGGAGE", "CRUISE",
                    "ISLAND", "DESERT", "JOURNEY", "TICKET", "SUITCASE", "HARBOR", "TUNNEL",
                    "BRIDGE", "MAP", "CABIN", "SAFARI", "VOYAGE", "AIRPORT"]
        ),
        WordPack(
            id: "space", name: "Space", symbol: "moon.stars.fill", tint: 0x8A63C9, isPro: true,
            words: ["COMET", "ORBIT", "MARS", "VENUS", "PLUTO", "GALAXY", "ROCKET", "NEBULA",
                    "METEOR", "SATURN", "COSMOS", "ECLIPSE", "STARDUST", "QUASAR", "GRAVITY",
                    "CRATER", "PLANET", "SHUTTLE", "LUNAR", "SOLAR"]
        ),
        WordPack(
            id: "nature", name: "Nature", symbol: "leaf.fill", tint: 0x3E9E6E, isPro: true,
            words: ["RIVER", "FOREST", "MEADOW", "CANYON", "PEBBLE", "BLOSSOM", "MAPLE",
                    "WILLOW", "STREAM", "VALLEY", "ORCHID", "BOULDER", "PRAIRIE", "GLACIER",
                    "THICKET", "FERN", "MOSS", "DUNE", "MARSH", "GROVE"]
        ),
        WordPack(
            id: "sports", name: "Sports", symbol: "figure.run", tint: 0xC9892B, isPro: true,
            words: ["SOCCER", "TENNIS", "HOCKEY", "BOXING", "ROWING", "SKIING", "RUGBY",
                    "CRICKET", "ARCHERY", "CYCLING", "SAILING", "DIVING", "FENCING", "GOLF",
                    "JUDO", "RELAY", "SPRINT", "HURDLE", "BOWLING", "SURFING"]
        ),
        WordPack(
            id: "music", name: "Music", symbol: "music.note", tint: 0xD8536A, isPro: true,
            words: ["PIANO", "GUITAR", "VIOLIN", "DRUMS", "FLUTE", "CELLO", "TRUMPET",
                    "MELODY", "RHYTHM", "CHORUS", "TEMPO", "OCTAVE", "HARMONY", "BALLAD",
                    "ANTHEM", "BANJO", "OBOE", "LYRICS", "CHORD", "ENCORE"]
        ),
        WordPack(
            id: "body", name: "Body", symbol: "heart.fill", tint: 0xC2473A, isPro: true,
            words: ["HEART", "ELBOW", "ANKLE", "WRIST", "SPINE", "MUSCLE", "FINGER", "SHOULDER",
                    "KIDNEY", "THUMB", "KNEE", "TONGUE", "EYELID", "STOMACH", "JAW",
                    "PALM", "RIB", "HEEL", "LUNG", "NERVE"]
        ),
        WordPack(
            id: "weather", name: "Weather", symbol: "cloud.sun.fill", tint: 0x5AA5C9, isPro: true,
            words: ["CLOUD", "STORM", "BREEZE", "FROST", "THUNDER", "RAINBOW", "DRIZZLE",
                    "BLIZZARD", "SUNSHINE", "HUMID", "CYCLONE", "HAIL", "SLEET", "GUST",
                    "OVERCAST", "MIST", "FOG", "DEW", "MONSOON", "TORNADO"]
        ),
        WordPack(
            id: "jobs", name: "Jobs", symbol: "briefcase.fill", tint: 0x7A6B60, isPro: true,
            words: ["DOCTOR", "TEACHER", "PILOT", "CHEF", "NURSE", "FARMER", "LAWYER",
                    "ARTIST", "WRITER", "PLUMBER", "DENTIST", "BAKER", "TAILOR", "ENGINEER",
                    "SAILOR", "JUDGE", "GUARD", "MINER", "WAITER", "PORTER"]
        ),
        WordPack(
            id: "kitchen", name: "Kitchen", symbol: "cooktop.fill", tint: 0xE0654E, isPro: true,
            words: ["SPOON", "KETTLE", "WHISK", "GRATER", "SKILLET", "BLENDER", "TOASTER",
                    "COLANDER", "SPATULA", "PEELER", "LADLE", "SAUCEPAN", "CLEAVER", "TONGS",
                    "STRAINER", "MIXER", "BOWL", "PLATTER", "KNIFE", "MUG"]
        )
    ]

    static var freePacks: [WordPack] { all.filter { !$0.isPro } }

    static func pack(id: String) -> WordPack? {
        all.first { $0.id == id }
    }
}
