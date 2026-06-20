import Foundation
import SwiftData

enum Sport: String, Codable, CaseIterable {
    case nfl = "NFL"
    case nba = "NBA"
    case mlb = "MLB"
    case nhl = "NHL"
    case soccer = "Soccer"
    case college = "College Football"
    case other = "Other"

    var icon: String {
        switch self {
        case .nfl: return "football.fill"
        case .nba: return "basketball.fill"
        case .mlb: return "baseball.fill"
        case .nhl: return "hockey.puck.fill"
        case .soccer: return "soccerball"
        case .college: return "football.fill"
        case .other: return "trophy.fill"
        }
    }
}

enum PickResult: String, Codable {
    case pending = "Pending"
    case correct = "Correct"
    case incorrect = "Incorrect"
    case push = "Push"
}

enum PickType: String, Codable, CaseIterable {
    case moneyline = "Moneyline"
    case spread = "Spread"
    case overUnder = "Over/Under"
    case parlay = "Parlay"
    case prop = "Prop Bet"
}

enum ConfidenceLevel: Int, Codable, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case lock = 4

    var label: String {
        switch self {
        case .low: return "Lean"
        case .medium: return "Like It"
        case .high: return "Strong"
        case .lock: return "Lock 🔒"
        }
    }

    var color: String {
        switch self {
        case .low: return "gray"
        case .medium: return "blue"
        case .high: return "orange"
        case .lock: return "red"
        }
    }
}

@Model
final class RivalLeague {
    var id: UUID
    var name: String
    var sport: Sport
    var season: String
    var emoji: String
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \RivalTeam.league)
    var teams: [RivalTeam]

    @Relationship(deleteRule: .cascade, inverse: \Matchup.league)
    var matchups: [Matchup]

    init(name: String, sport: Sport, season: String = "2025") {
        self.id = UUID()
        self.name = name
        self.sport = sport
        self.season = season
        self.emoji = "🏆"
        self.sortOrder = 0
        self.teams = []
        self.matchups = []
    }
}

@Model
final class RivalTeam {
    var id: UUID
    var name: String
    var city: String
    var abbreviation: String
    var primaryColor: String
    var emoji: String
    var league: RivalLeague?

    init(name: String, city: String, abbreviation: String, league: RivalLeague) {
        self.id = UUID()
        self.name = name
        self.city = city
        self.abbreviation = abbreviation
        self.primaryColor = "#cc0000"
        self.emoji = "🏈"
        self.league = league
    }

    var fullName: String { "\(city) \(name)" }
}

@Model
final class Matchup {
    var id: UUID
    var homeTeamName: String
    var awayTeamName: String
    var gameDate: Date
    var sport: Sport
    var homeScore: Int
    var awayScore: Int
    var isCompleted: Bool
    var week: Int
    var notes: String
    var league: RivalLeague?

    @Relationship(deleteRule: .cascade, inverse: \Pick.matchup)
    var picks: [Pick]

    init(homeTeamName: String, awayTeamName: String, gameDate: Date, sport: Sport, league: RivalLeague) {
        self.id = UUID()
        self.homeTeamName = homeTeamName
        self.awayTeamName = awayTeamName
        self.gameDate = gameDate
        self.sport = sport
        self.homeScore = 0
        self.awayScore = 0
        self.isCompleted = false
        self.week = 1
        self.notes = ""
        self.league = league
        self.picks = []
    }

    var displayScore: String {
        guard isCompleted else { return "vs" }
        return "\(awayScore)–\(homeScore)"
    }
}

@Model
final class Pick {
    var id: UUID
    var pickedTeamName: String
    var pickType: PickType
    var confidence: ConfidenceLevel
    var spread: Double
    var result: PickResult
    var notes: String
    var createdAt: Date
    var matchup: Matchup?

    init(pickedTeamName: String, pickType: PickType, confidence: ConfidenceLevel, matchup: Matchup) {
        self.id = UUID()
        self.pickedTeamName = pickedTeamName
        self.pickType = pickType
        self.confidence = confidence
        self.spread = 0.0
        self.result = .pending
        self.notes = ""
        self.createdAt = Date()
        self.matchup = matchup
    }
}

@Model
final class RivalSettings {
    var onboardingComplete: Bool
    var username: String
    var favoriteSport: Sport
    var showOdds: Bool
    var defaultConfidence: ConfidenceLevel

    init() {
        self.onboardingComplete = false
        self.username = ""
        self.favoriteSport = .nfl
        self.showOdds = true
        self.defaultConfidence = .medium
    }
}

// Seeded NFL + NBA teams for quick setup
extension RivalLeague {
    static func seededNFL() -> (league: RivalLeague, teams: [(String, String, String)]) {
        let league = RivalLeague(name: "NFL 2025", sport: .nfl, season: "2025")
        let teams: [(String, String, String)] = [
            ("Chiefs", "Kansas City", "KC"),
            ("Eagles", "Philadelphia", "PHI"),
            ("49ers", "San Francisco", "SF"),
            ("Cowboys", "Dallas", "DAL"),
            ("Bills", "Buffalo", "BUF"),
            ("Ravens", "Baltimore", "BAL"),
            ("Dolphins", "Miami", "MIA"),
            ("Bengals", "Cincinnati", "CIN"),
            ("Lions", "Detroit", "DET"),
            ("Packers", "Green Bay", "GB"),
            ("Vikings", "Minnesota", "MIN"),
            ("Bears", "Chicago", "CHI"),
            ("Rams", "Los Angeles", "LAR"),
            ("Seahawks", "Seattle", "SEA"),
            ("Chargers", "Los Angeles", "LAC"),
            ("Raiders", "Las Vegas", "LV"),
            ("Broncos", "Denver", "DEN"),
            ("Texans", "Houston", "HOU"),
            ("Colts", "Indianapolis", "IND"),
            ("Jaguars", "Jacksonville", "JAX"),
            ("Titans", "Tennessee", "TEN"),
            ("Steelers", "Pittsburgh", "PIT"),
            ("Browns", "Cleveland", "CLE"),
            ("Giants", "New York", "NYG"),
            ("Jets", "New York", "NYJ"),
            ("Patriots", "New England", "NE"),
            ("Panthers", "Carolina", "CAR"),
            ("Saints", "New Orleans", "NO"),
            ("Buccaneers", "Tampa Bay", "TB"),
            ("Falcons", "Atlanta", "ATL"),
            ("Cardinals", "Arizona", "ARI"),
            ("Commanders", "Washington", "WSH"),
        ]
        return (league, teams)
    }

    static func seededNBA() -> (league: RivalLeague, teams: [(String, String, String)]) {
        let league = RivalLeague(name: "NBA 2025-26", sport: .nba, season: "2025-26")
        let teams: [(String, String, String)] = [
            ("Lakers", "Los Angeles", "LAL"),
            ("Celtics", "Boston", "BOS"),
            ("Warriors", "Golden State", "GSW"),
            ("Bucks", "Milwaukee", "MIL"),
            ("76ers", "Philadelphia", "PHI"),
            ("Heat", "Miami", "MIA"),
            ("Nuggets", "Denver", "DEN"),
            ("Suns", "Phoenix", "PHX"),
            ("Clippers", "Los Angeles", "LAC"),
            ("Mavericks", "Dallas", "DAL"),
            ("Knicks", "New York", "NYK"),
            ("Bulls", "Chicago", "CHI"),
            ("Nets", "Brooklyn", "BKN"),
            ("Raptors", "Toronto", "TOR"),
            ("Hawks", "Atlanta", "ATL"),
            ("Cavaliers", "Cleveland", "CLE"),
            ("Pacers", "Indiana", "IND"),
            ("Magic", "Orlando", "ORL"),
            ("Wizards", "Washington", "WAS"),
            ("Hornets", "Charlotte", "CHA"),
            ("Thunder", "Oklahoma City", "OKC"),
            ("Grizzlies", "Memphis", "MEM"),
            ("Pelicans", "New Orleans", "NOP"),
            ("Spurs", "San Antonio", "SAS"),
            ("Rockets", "Houston", "HOU"),
            ("Jazz", "Utah", "UTA"),
            ("Kings", "Sacramento", "SAC"),
            ("Trail Blazers", "Portland", "POR"),
            ("Timberwolves", "Minnesota", "MIN"),
            ("Pistons", "Detroit", "DET"),
        ]
        return (league, teams)
    }
}
