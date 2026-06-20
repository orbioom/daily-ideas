import Foundation
import SwiftData

enum StoryGenre: String, Codable, CaseIterable {
    case adventure = "Adventure"
    case fantasy = "Fantasy"
    case animals = "Animals"
    case friendship = "Friendship"
    case mystery = "Mystery"
    case bedtime = "Bedtime"
    case silly = "Silly"
    case space = "Space"

    var icon: String {
        switch self {
        case .adventure: return "map.fill"
        case .fantasy: return "wand.and.stars"
        case .animals: return "pawprint.fill"
        case .friendship: return "heart.fill"
        case .mystery: return "magnifyingglass"
        case .bedtime: return "moon.stars.fill"
        case .silly: return "face.smiling.fill"
        case .space: return "star.fill"
        }
    }
}

enum AgeGroup: String, Codable, CaseIterable {
    case toddler = "2–4 yrs"
    case preschool = "4–6 yrs"
    case earlyReader = "6–8 yrs"
    case middleGrade = "8–10 yrs"
}

enum CharacterRole: String, Codable, CaseIterable {
    case hero = "Hero"
    case sidekick = "Sidekick"
    case villain = "Villain"
    case mentor = "Mentor"
    case magical = "Magical Being"
    case animal = "Animal Companion"
}

enum StoryLength: String, Codable, CaseIterable {
    case short = "Short (~3 min)"
    case medium = "Medium (~6 min)"
    case long = "Long (~10 min)"

    var pageCount: Int {
        switch self {
        case .short: return 5
        case .medium: return 8
        case .long: return 12
        }
    }
}

@Model
final class FableStory {
    var id: UUID
    var title: String
    var genre: StoryGenre
    var ageGroup: AgeGroup
    var length: StoryLength
    var content: String
    var isFavorite: Bool
    var lastReadAt: Date?
    var readCount: Int
    var createdAt: Date
    var moralLesson: String
    var settingDescription: String

    @Relationship(deleteRule: .cascade, inverse: \StoryCharacter.story)
    var characters: [StoryCharacter]

    @Relationship(deleteRule: .cascade, inverse: \StoryPage.story)
    var pages: [StoryPage]

    init(title: String, genre: StoryGenre, ageGroup: AgeGroup) {
        self.id = UUID()
        self.title = title
        self.genre = genre
        self.ageGroup = ageGroup
        self.length = .medium
        self.content = ""
        self.isFavorite = false
        self.lastReadAt = nil
        self.readCount = 0
        self.createdAt = Date()
        self.moralLesson = ""
        self.settingDescription = ""
        self.characters = []
        self.pages = []
    }

    var sortedPages: [StoryPage] { pages.sorted { $0.pageNumber < $1.pageNumber } }
    var estimatedReadTime: String {
        let words = content.split(separator: " ").count
        let minutes = max(1, words / 120)
        return "\(minutes) min"
    }
}

@Model
final class StoryCharacter {
    var id: UUID
    var name: String
    var role: CharacterRole
    var description: String
    var traits: String
    var emoji: String
    var story: FableStory?

    init(name: String, role: CharacterRole, story: FableStory) {
        self.id = UUID()
        self.name = name
        self.role = role
        self.description = ""
        self.traits = ""
        self.emoji = "⭐️"
        self.story = story
    }
}

@Model
final class StoryPage {
    var id: UUID
    var pageNumber: Int
    var text: String
    var illustrationNote: String
    var story: FableStory?

    init(pageNumber: Int, text: String, story: FableStory) {
        self.id = UUID()
        self.pageNumber = pageNumber
        self.text = text
        self.illustrationNote = ""
        self.story = story
    }
}

@Model
final class FableSettings {
    var onboardingComplete: Bool
    var childName: String
    var preferredAgeGroup: AgeGroup
    var autoPlayNarration: Bool
    var narrationSpeed: Double
    var darkReaderMode: Bool
    var defaultGenre: StoryGenre

    init() {
        self.onboardingComplete = false
        self.childName = ""
        self.preferredAgeGroup = .preschool
        self.autoPlayNarration = false
        self.narrationSpeed = 0.5
        self.darkReaderMode = true
        self.defaultGenre = .bedtime
    }
}

// Built-in story templates
struct StoryTemplate: Identifiable {
    let id = UUID()
    let title: String
    let genre: StoryGenre
    let ageGroup: AgeGroup
    let moralLesson: String
    let settingDescription: String
    let pages: [String]
    let characters: [(name: String, role: CharacterRole, emoji: String)]
}

extension StoryTemplate {
    static let templates: [StoryTemplate] = [
        StoryTemplate(
            title: "The Brave Little Firefly",
            genre: .bedtime,
            ageGroup: .preschool,
            moralLesson: "Courage comes in all sizes.",
            settingDescription: "A magical meadow on a warm summer night",
            pages: [
                "In a meadow full of tall grass and sleepy flowers, there lived a tiny firefly named Pip.",
                "Every night, the other fireflies would light up the sky. But Pip's light was very, very small.",
                "\"What if nobody notices me?\" Pip wondered, hiding under a leaf.",
                "One dark, cloudy night, a lost baby bunny sat crying in the meadow.",
                "Pip blinked her tiny light — once, twice, three times. The bunny saw it!",
                "\"Follow my light,\" said Pip. And the bunny hopped safely back home.",
                "From then on, Pip knew: even the smallest light can guide someone through the dark.",
                "She blinked her light proudly, and all the meadow sparkled along with her. The End."
            ],
            characters: [
                ("Pip", .hero, "✨"),
                ("Baby Bunny", .sidekick, "🐰"),
                ("Elder Firefly", .mentor, "🌟")
            ]
        ),
        StoryTemplate(
            title: "Captain Cosmo's Star Map",
            genre: .space,
            ageGroup: .earlyReader,
            moralLesson: "Asking for help is a sign of strength.",
            settingDescription: "A colorful galaxy filled with friendly planets",
            pages: [
                "Captain Cosmo zoomed through the galaxy in her rocket ship, the Starduster.",
                "She was searching for the lost Star Map that could show every planet in the universe.",
                "\"I can find it myself!\" she declared, flying past the Rings of Rumbulus.",
                "But the galaxy was huge, and Cosmo got very, very lost.",
                "A kind space whale named Blubble swam by. \"Need help?\" he asked.",
                "Cosmo almost said no — but then she smiled. \"Yes, please!\"",
                "Together they searched every nebula and comet trail until — there it was!",
                "\"The best adventures,\" Cosmo said, hugging Blubble, \"are the ones we share.\" The End."
            ],
            characters: [
                ("Captain Cosmo", .hero, "🚀"),
                ("Blubble", .animal, "🐋"),
                ("The Star Map", .magical, "🗺️")
            ]
        ),
        StoryTemplate(
            title: "The Dragon Who Was Afraid of Fire",
            genre: .fantasy,
            ageGroup: .earlyReader,
            moralLesson: "It's okay to be different.",
            settingDescription: "A mountain kingdom where dragons rule the sky",
            pages: [
                "In the highest mountain in the land lived a dragon named Fern — who was terrified of fire.",
                "All the other dragons breathed great plumes of flame. Fern breathed only flowers.",
                "\"Fern is broken,\" the older dragons whispered.",
                "One spring day, a terrible frost swept the kingdom, freezing all the flowers and food.",
                "The people were cold and hungry. The fire dragons tried to help, but their flames were too big.",
                "Then Fern stepped forward and breathed — gentle, warm blossoms bloomed on every doorstep.",
                "The kingdom was saved by the softest breath of all.",
                "\"Your gift is your own,\" said the dragon queen. \"And it is precious.\" The End."
            ],
            characters: [
                ("Fern", .hero, "🐉"),
                ("Dragon Queen", .mentor, "👑"),
                ("Forest Fairy", .magical, "🧚")
            ]
        ),
        StoryTemplate(
            title: "Milo and the Missing Cookie",
            genre: .mystery,
            ageGroup: .toddler,
            moralLesson: "Honesty feels better than hiding.",
            settingDescription: "A cozy kitchen and backyard garden",
            pages: [
                "Milo the mouse loved cookies more than anything in the world.",
                "One morning, Grandma's best cookie had gone missing from the jar.",
                "\"Who took it?\" Grandma said, hands on hips. Milo looked at his toes.",
                "His friend Chip the chipmunk looked in the garden. No cookie there.",
                "They searched the whole house — under the sofa, behind the clock.",
                "Finally, Milo whispered: \"I took it. I'm sorry, Grandma. It looked so yummy.\"",
                "Grandma hugged him tight. \"Thank you for telling the truth. Want to bake more — together?\"",
                "They baked twelve cookies. Milo learned that honesty tastes even sweeter. The End."
            ],
            characters: [
                ("Milo", .hero, "🐭"),
                ("Chip", .sidekick, "🐿️"),
                ("Grandma", .mentor, "👵")
            ]
        ),
        StoryTemplate(
            title: "The Sneezing Forest",
            genre: .silly,
            ageGroup: .preschool,
            moralLesson: "Laughter brings friends together.",
            settingDescription: "An enchanted forest full of sneezing trees",
            pages: [
                "One Tuesday, every tree in the Whimble Forest caught a terrible sneezing cold.",
                "ACHOO! Leaves flew off. ACHOO! Acorns shot across the sky like tiny rockets.",
                "A girl named Poppy walked in and got hit by three acorns and one very surprised squirrel.",
                "\"Bless you!\" she called to the nearest oak. It sneezed again — right onto her hat.",
                "Poppy giggled so hard she fell into a pile of leaves. The leaves giggled back.",
                "She sang the trees a silly sneeze song: \"Achoo, kazoo, the sky is blue and you sneezed on my shoe!\"",
                "The trees laughed so hard they stopped sneezing. The forest rang with giggles.",
                "Poppy made a hundred new tree friends that day. The End."
            ],
            characters: [
                ("Poppy", .hero, "👧"),
                ("Grumble Oak", .villain, "🌳"),
                ("Giggle Squirrel", .animal, "🐿️")
            ]
        ),
        StoryTemplate(
            title: "Two Bears, One Cave",
            genre: .friendship,
            ageGroup: .preschool,
            moralLesson: "Sharing makes everything better.",
            settingDescription: "A cozy forest with one very warm cave",
            pages: [
                "When the snow fell, Bear Basil and Bear Birch both found the same cave at the same time.",
                "\"It's mine!\" said Basil. \"No, mine!\" said Birch. They glared at each other all night.",
                "The cave was cold when they sat far apart. Their breath made tiny puffs of frost.",
                "\"What if we moved just a little closer?\" Birch asked. \"Just to stay warm,\" Basil agreed.",
                "They huddled together and the cave grew wonderfully warm.",
                "\"I have honey,\" said Birch. \"I have berries,\" said Basil.",
                "They shared supper, told stories, and laughed until the storm passed.",
                "By spring, the cave was theirs — and so was the best friendship in the forest. The End."
            ],
            characters: [
                ("Bear Basil", .hero, "🐻"),
                ("Bear Birch", .hero, "🐻‍❄️"),
                ("Wise Owl", .mentor, "🦉")
            ]
        )
    ]
}
