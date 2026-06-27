import SwiftData
import Foundation

enum FightResult: String, CaseIterable, Codable {
    case win = "Win"
    case loss = "Loss"
    case draw = "Draw"
    case noContest = "No Contest"

    var icon: String {
        switch self {
        case .win: return "trophy.fill"
        case .loss: return "xmark.circle.fill"
        case .draw: return "equal.circle.fill"
        case .noContest: return "minus.circle.fill"
        }
    }
}

enum FightMethod: String, CaseIterable, Codable {
    case ko = "KO/TKO"
    case decision = "Decision"
    case submission = "Submission"
    case pointsDisqualification = "DQ/Points"
    case retiredCorner = "Corner Stoppage"
    case unanimous = "Unanimous Decision"
    case split = "Split Decision"
    case majority = "Majority Decision"
}

@Model
final class FightRecord {
    var id: UUID
    var date: Date
    var opponent: String
    var event: String
    var resultRaw: String
    var methodRaw: String
    var round: Int
    var roundTime: String
    var disciplineRaw: String
    var notes: String
    var isAmateur: Bool

    init(
        date: Date = Date(),
        opponent: String,
        event: String = "",
        result: FightResult = .win,
        method: FightMethod = .decision,
        round: Int = 0,
        roundTime: String = "",
        discipline: Discipline = .boxing,
        notes: String = "",
        isAmateur: Bool = true
    ) {
        self.id = UUID()
        self.date = date
        self.opponent = opponent
        self.event = event
        self.resultRaw = result.rawValue
        self.methodRaw = method.rawValue
        self.round = round
        self.roundTime = roundTime
        self.disciplineRaw = discipline.rawValue
        self.notes = notes
        self.isAmateur = isAmateur
    }

    var result: FightResult {
        get { FightResult(rawValue: resultRaw) ?? .win }
        set { resultRaw = newValue.rawValue }
    }

    var method: FightMethod {
        get { FightMethod(rawValue: methodRaw) ?? .decision }
        set { methodRaw = newValue.rawValue }
    }

    var discipline: Discipline {
        get { Discipline(rawValue: disciplineRaw) ?? .boxing }
        set { disciplineRaw = newValue.rawValue }
    }
}
