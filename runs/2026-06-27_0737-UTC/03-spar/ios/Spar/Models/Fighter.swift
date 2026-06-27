import SwiftData
import Foundation

enum Discipline: String, CaseIterable, Codable {
    case boxing = "Boxing"
    case kickboxing = "Kickboxing"
    case muayThai = "Muay Thai"
    case mma = "MMA"
    case karate = "Karate"
    case taekwondo = "Taekwondo"
    case westernBoxing = "Western Boxing"

    var icon: String {
        switch self {
        case .boxing, .westernBoxing: return "figure.boxing"
        case .kickboxing, .muayThai: return "figure.kickboxing"
        case .mma: return "figure.martial.arts"
        case .karate, .taekwondo: return "figure.karate"
        }
    }
}

enum WeightClass: String, CaseIterable, Codable {
    case strawweight = "Strawweight (≤115 lbs)"
    case flyweight = "Flyweight (≤125 lbs)"
    case bantamweight = "Bantamweight (≤135 lbs)"
    case featherweight = "Featherweight (≤145 lbs)"
    case lightweight = "Lightweight (≤155 lbs)"
    case welterweight = "Welterweight (≤170 lbs)"
    case middleweight = "Middleweight (≤185 lbs)"
    case lightheavy = "Light Heavy (≤205 lbs)"
    case heavyweight = "Heavyweight (≤265 lbs)"
    case superheavy = "Super Heavyweight (265+ lbs)"
}

@Model
final class Fighter {
    var id: UUID
    var name: String
    var disciplineRaw: String
    var weightClassRaw: String
    var stance: String
    var trainingYears: Int
    var beltOrRank: String
    var goals: String
    var createdAt: Date

    init(
        name: String,
        discipline: Discipline = .boxing,
        weightClass: WeightClass = .welterweight,
        stance: String = "Orthodox",
        trainingYears: Int = 0,
        beltOrRank: String = "",
        goals: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.disciplineRaw = discipline.rawValue
        self.weightClassRaw = weightClass.rawValue
        self.stance = stance
        self.trainingYears = trainingYears
        self.beltOrRank = beltOrRank
        self.goals = goals
        self.createdAt = Date()
    }

    var discipline: Discipline {
        get { Discipline(rawValue: disciplineRaw) ?? .boxing }
        set { disciplineRaw = newValue.rawValue }
    }

    var weightClass: WeightClass {
        get { WeightClass(rawValue: weightClassRaw) ?? .welterweight }
        set { weightClassRaw = newValue.rawValue }
    }
}
