import Foundation

/// Whether a lesson is in the free tier or gated behind Dactyl Pro.
enum LessonTier {
    case free
    case pro
}

/// A bundled, static curriculum lesson.
struct Lesson: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let tier: LessonTier
    /// The keys this lesson focuses on (for the next-key guide & framing).
    let focusKeys: [String]
    /// The text the learner drills.
    let drillText: String
    let order: Int

    var isFree: Bool { tier == .free }
}

/// The bundled curriculum, ordered from foundational to advanced.
enum Curriculum {
    static let lessons: [Lesson] = [
        Lesson(
            id: "home-row",
            title: "Home Row",
            subtitle: "asdf jkl; — your anchor",
            tier: .free,
            focusKeys: ["a", "s", "d", "f", "j", "k", "l", ";"],
            drillText: "asdf jkl; asdf jkl; fjfj dkdk slsl a;a; jfjf kdkd sad lad ask all fall lass jak dad fad",
            order: 0
        ),
        Lesson(
            id: "home-row-words",
            title: "Home Row Words",
            subtitle: "Real words, home keys",
            tier: .free,
            focusKeys: ["a", "s", "d", "f", "j", "k", "l"],
            drillText: "a lad asks a sad lass all fall as a flask falls a salad lad adds a flask all add salad",
            order: 1
        ),
        Lesson(
            id: "top-row",
            title: "Top Row",
            subtitle: "qwerty uiop reach",
            tier: .pro,
            focusKeys: ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
            drillText: "the quiet otter ran top tier pity wire your tower require try pour write quote pretty",
            order: 2
        ),
        Lesson(
            id: "bottom-row",
            title: "Bottom Row",
            subtitle: "zxcvb nm reach",
            tier: .pro,
            focusKeys: ["z", "x", "c", "v", "b", "n", "m"],
            drillText: "zebra mix vivid combo never minimum amazing buzzing column maven vacant nimble examine",
            order: 3
        ),
        Lesson(
            id: "numbers",
            title: "Numbers",
            subtitle: "The number row",
            tier: .pro,
            focusKeys: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
            drillText: "1 2 3 4 5 6 7 8 9 0 call 555 0192 buy 24 add 360 area 1024 mix 73 and 86 floor 12 row 9",
            order: 4
        ),
        Lesson(
            id: "punctuation",
            title: "Punctuation",
            subtitle: ", . ' ? ! and friends",
            tier: .pro,
            focusKeys: [",", ".", "'", "?", "!", ";", ":"],
            drillText: "wait, really? yes! it's done. stop; go. who's there? it's me, again. now, then: begin!",
            order: 5
        ),
        Lesson(
            id: "capitals",
            title: "Capitals",
            subtitle: "Shift for uppercase",
            tier: .pro,
            focusKeys: ["Shift", "A", "T", "S"],
            drillText: "The Sun Rose Over Tall Pines. Maya And Theo Walked North. We Saw A Red Fox Near The River.",
            order: 6
        ),
        Lesson(
            id: "common-words",
            title: "Common Words",
            subtitle: "The 100 most-used words",
            tier: .pro,
            focusKeys: [],
            drillText: "the of and a to in is you that it he was for on are as with his they at be this have from",
            order: 7
        ),
        Lesson(
            id: "sentences",
            title: "Sentences",
            subtitle: "Full flowing prose",
            tier: .pro,
            focusKeys: [],
            drillText: "A calm mind types faster than a hurried one. Practice a little every day and the speed follows. Smooth is steady, and steady becomes quick.",
            order: 8
        )
    ]

    static let freeLessonIDs: Set<String> = Set(lessons.filter { $0.isFree }.map { $0.id })

    static func lesson(id: String) -> Lesson? {
        lessons.first { $0.id == id }
    }
}
