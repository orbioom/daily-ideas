import Foundation
import SwiftData

enum ProjectStatus: String, CaseIterable, Codable {
    case idea = "Idea"
    case outlining = "Outlining"
    case drafting = "Drafting"
    case revising = "Revising"
    case complete = "Complete"
    case shelved = "Shelved"

    var color: String {
        switch self {
        case .idea: return "gray"
        case .outlining: return "yellow"
        case .drafting: return "blue"
        case .revising: return "orange"
        case .complete: return "green"
        case .shelved: return "red"
        }
    }
}

enum ProjectGenre: String, CaseIterable, Codable {
    case fantasy = "Fantasy"
    case scienceFiction = "Science Fiction"
    case romance = "Romance"
    case thriller = "Thriller"
    case mystery = "Mystery"
    case horror = "Horror"
    case literaryFiction = "Literary Fiction"
    case historicalFiction = "Historical Fiction"
    case youngAdult = "Young Adult"
    case middleGrade = "Middle Grade"
    case memoir = "Memoir"
    case narrative = "Narrative Non-Fiction"
    case other = "Other"
}

enum CharacterRole: String, CaseIterable, Codable {
    case protagonist = "Protagonist"
    case antagonist = "Antagonist"
    case deuteragonist = "Deuteragonist"
    case mentor = "Mentor"
    case loveInterest = "Love Interest"
    case sidekick = "Sidekick"
    case foil = "Foil"
    case supporting = "Supporting"
    case minor = "Minor"
}

enum ChapterStatus: String, CaseIterable, Codable {
    case notStarted = "Not Started"
    case drafting = "Drafting"
    case drafted = "Drafted"
    case revising = "Revising"
    case done = "Done"
}

enum PlotTemplate: String, CaseIterable, Identifiable {
    case threeAct = "Three-Act Structure"
    case heroJourney = "Hero's Journey"
    case saveCat = "Save the Cat Beat Sheet"
    case fiveAct = "Five-Act Structure"
    case blank = "Blank"

    var id: String { rawValue }

    var beats: [String] {
        switch self {
        case .threeAct:
            return ["Act 1: Setup", "Inciting Incident", "Act 1 Turn", "Act 2: Rising Action", "Midpoint", "Act 2 Dark Night", "Act 3: Climax", "Resolution"]
        case .heroJourney:
            return ["Ordinary World", "Call to Adventure", "Refusal of the Call", "Meeting the Mentor", "Crossing the Threshold", "Tests / Allies / Enemies", "Approach to Inmost Cave", "The Ordeal", "Reward", "The Road Back", "Resurrection", "Return with Elixir"]
        case .saveCat:
            return ["Opening Image", "Theme Stated", "Set-Up", "Catalyst", "Debate", "Break into Two", "B Story", "Fun & Games", "Midpoint", "Bad Guys Close In", "All Is Lost", "Dark Night of the Soul", "Break into Three", "Finale", "Final Image"]
        case .fiveAct:
            return ["Act 1: Exposition", "Act 2: Rising Action", "Act 3: Climax", "Act 4: Falling Action", "Act 5: Denouement"]
        case .blank:
            return []
        }
    }
}

@Model
final class DraftProject {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var title: String
    var genre: String
    var logline: String
    var synopsis: String
    var statusRaw: String
    var targetWordCount: Int
    var currentWordCount: Int
    var accentColorHex: String

    @Relationship(deleteRule: .cascade, inverse: \DraftCharacter.project)
    var characters: [DraftCharacter]

    @Relationship(deleteRule: .cascade, inverse: \DraftChapter.project)
    var chapters: [DraftChapter]

    @Relationship(deleteRule: .cascade, inverse: \PlotBeat.project)
    var plotBeats: [PlotBeat]

    init(title: String = "Untitled Project", genre: String = "Other") {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.title = title
        self.genre = genre
        self.logline = ""
        self.synopsis = ""
        self.statusRaw = ProjectStatus.idea.rawValue
        self.targetWordCount = 80000
        self.currentWordCount = 0
        self.accentColorHex = "#D48B2A"
        self.characters = []
        self.chapters = []
        self.plotBeats = []
    }

    var status: ProjectStatus { ProjectStatus(rawValue: statusRaw) ?? .idea }
    var progressFraction: Double {
        guard targetWordCount > 0 else { return 0 }
        return min(1.0, Double(currentWordCount) / Double(targetWordCount))
    }
    var orderedChapters: [DraftChapter] { chapters.sorted { $0.number < $1.number } }
}

@Model
final class DraftCharacter {
    var id: UUID
    var name: String
    var roleRaw: String
    var age: String
    var traits: String
    var motivation: String
    var arc: String
    var notes: String
    var project: DraftProject?

    init(name: String = "", role: CharacterRole = .supporting, project: DraftProject? = nil) {
        self.id = UUID()
        self.name = name
        self.roleRaw = role.rawValue
        self.age = ""
        self.traits = ""
        self.motivation = ""
        self.arc = ""
        self.notes = ""
        self.project = project
    }

    var role: CharacterRole { CharacterRole(rawValue: roleRaw) ?? .supporting }
}

@Model
final class DraftChapter {
    var id: UUID
    var number: Int
    var title: String
    var synopsis: String
    var wordCount: Int
    var statusRaw: String
    var notes: String
    var project: DraftProject?

    @Relationship(deleteRule: .cascade, inverse: \DraftScene.chapter)
    var scenes: [DraftScene]

    init(number: Int = 1, title: String = "", project: DraftProject? = nil) {
        self.id = UUID()
        self.number = number
        self.title = title
        self.synopsis = ""
        self.wordCount = 0
        self.statusRaw = ChapterStatus.notStarted.rawValue
        self.notes = ""
        self.project = project
        self.scenes = []
    }

    var status: ChapterStatus { ChapterStatus(rawValue: statusRaw) ?? .notStarted }
}

@Model
final class DraftScene {
    var id: UUID
    var order: Int
    var title: String
    var location: String
    var povCharacter: String
    var summary: String
    var wordCount: Int
    var chapter: DraftChapter?

    init(order: Int = 0, title: String = "", chapter: DraftChapter? = nil) {
        self.id = UUID()
        self.order = order
        self.title = title
        self.location = ""
        self.povCharacter = ""
        self.summary = ""
        self.wordCount = 0
        self.chapter = chapter
    }
}

@Model
final class PlotBeat {
    var id: UUID
    var order: Int
    var name: String
    var notes: String
    var isChecked: Bool
    var project: DraftProject?

    init(order: Int = 0, name: String = "", project: DraftProject? = nil) {
        self.id = UUID()
        self.order = order
        self.name = name
        self.notes = ""
        self.isChecked = false
        self.project = project
    }
}
