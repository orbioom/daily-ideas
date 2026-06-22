import Foundation

struct WordPack: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let description: String
    let words: [String]
}

struct WordPackLibrary {
    static let builtInPacks: [WordPack] = [
        WordPack(
            name: "Baby Shower",
            emoji: "🍼",
            description: "Perfect for celebrating a new arrival",
            words: [
                "diaper", "onesie", "pacifier", "crib", "stroller", "rattle", "swaddle",
                "burp cloth", "breast pump", "formula", "baby monitor", "changing table",
                "baby gate", "highchair", "car seat", "bath time", "lullaby", "first steps",
                "teething", "crawling", "peek-a-boo", "tummy time", "milestone", "newborn"
            ]
        ),
        WordPack(
            name: "Holiday Party",
            emoji: "🎄",
            description: "Festive fun for the holiday season",
            words: [
                "snowflake", "chimney", "reindeer", "ornament", "mistletoe", "tinsel",
                "gingerbread", "eggnog", "fruitcake", "stocking", "candy cane", "wreath",
                "Rudolph", "sleigh", "bells", "tobogganing", "hot cocoa", "caroling",
                "gift wrap", "snowball", "icicle", "frostbite", "polar express", "winter wonder"
            ]
        ),
        WordPack(
            name: "Sports Night",
            emoji: "🏈",
            description: "For the ultimate sports fan gathering",
            words: [
                "touchdown", "overtime", "penalty", "home run", "slam dunk", "hat trick",
                "ace serve", "birdie", "hole-in-one", "yellow card", "false start",
                "photo finish", "upset win", "comeback", "shutout", "buzzer beater",
                "free throw", "triple play", "grand slam", "power play", "offsides",
                "red zone", "fast break", "double fault"
            ]
        ),
        WordPack(
            name: "Back to School",
            emoji: "🎓",
            description: "Great for classrooms and school events",
            words: [
                "homework", "recess", "cafeteria", "principal", "chalkboard", "yearbook",
                "field trip", "report card", "pop quiz", "science fair", "hall pass",
                "detention", "graduation", "locker", "school bus", "backpack", "pencil case",
                "binder", "calculator", "highlighter", "school supplies", "substitute teacher",
                "parent night", "honor roll"
            ]
        ),
        WordPack(
            name: "Office Party",
            emoji: "💼",
            description: "Corporate buzzword bingo for work events",
            words: [
                "deadline", "synergy", "spreadsheet", "pivot table", "team building",
                "conference call", "bandwidth", "action items", "circle back", "deep dive",
                "low-hanging fruit", "move the needle", "touch base", "going forward",
                "best practices", "end of day", "take this offline", "boil the ocean",
                "on my radar", "let's loop in", "in the pipeline", "paradigm shift",
                "value add", "thinking outside the box"
            ]
        )
    ]

    static func pack(named name: String) -> WordPack? {
        builtInPacks.first { $0.name == name }
    }
}
