import Foundation
import SwiftData

// MARK: - Enums

enum BjjBelt: String, CaseIterable, Codable {
    case white = "White"
    case blue = "Blue"
    case purple = "Purple"
    case brown = "Brown"
    case black = "Black"

    var stripeMax: Int { self == .black ? 6 : 4 }

    var minMonths: Int {
        let map: [BjjBelt: Int] = [
            .white: 0,
            .blue: 12,
            .purple: 18,
            .brown: 18,
            .black: 36
        ]
        return map[self] ?? 0
    }

    var next: BjjBelt? {
        let all = BjjBelt.allCases
        guard let idx = all.firstIndex(of: self), idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }

    var displayName: String { rawValue }

    /// Approximate sessions needed to reach this belt from white
    var estimatedSessions: Int {
        switch self {
        case .white: return 0
        case .blue: return 100
        case .purple: return 300
        case .brown: return 600
        case .black: return 1000
        }
    }
}

enum TrainingType: String, CaseIterable, Codable {
    case gi = "Gi"
    case noGi = "No-Gi"
    case wrestling = "Wrestling"
    case striking = "Striking"
    case conditioning = "Conditioning"
    case openMat = "Open Mat"

    var icon: String {
        switch self {
        case .gi: return "figure.martial.arts"
        case .noGi: return "figure.wrestling"
        case .wrestling: return "figure.wrestling"
        case .striking: return "figure.boxing"
        case .conditioning: return "figure.run"
        case .openMat: return "circle.grid.3x3"
        }
    }
}

enum TechniqueCategory: String, CaseIterable, Codable {
    case guard_ = "Guard"
    case guardPasses = "Guard Passes"
    case takedowns = "Takedowns"
    case submissions = "Submissions"
    case sweeps = "Sweeps"
    case escapes = "Escapes"
    case back = "Back Control"
    case top = "Top Control"

    var icon: String {
        switch self {
        case .guard_: return "shield.fill"
        case .guardPasses: return "arrow.up.forward"
        case .takedowns: return "arrow.down.circle.fill"
        case .submissions: return "checkmark.seal.fill"
        case .sweeps: return "arrow.left.arrow.right"
        case .escapes: return "escape"
        case .back: return "arrow.backward.circle.fill"
        case .top: return "arrow.up.circle.fill"
        }
    }
}

// MARK: - SwiftData Models

@Model
final class TrainingSession {
    var date: Date
    var type: String           // TrainingType.rawValue
    var durationMinutes: Int
    var rounds: Int
    var notes: String
    var submissionsGot: Int
    var tapOuts: Int

    init(
        date: Date = .now,
        type: String = TrainingType.gi.rawValue,
        durationMinutes: Int = 60,
        rounds: Int = 5,
        notes: String = "",
        submissionsGot: Int = 0,
        tapOuts: Int = 0
    ) {
        self.date = date
        self.type = type
        self.durationMinutes = durationMinutes
        self.rounds = rounds
        self.notes = notes
        self.submissionsGot = submissionsGot
        self.tapOuts = tapOuts
    }

    var trainingType: TrainingType {
        TrainingType(rawValue: type) ?? .gi
    }
}

@Model
final class Technique {
    var name: String
    var category: String       // TechniqueCategory.rawValue
    var notes: String
    var isFavorite: Bool
    var drillCount: Int
    var addedDate: Date

    init(
        name: String,
        category: String,
        notes: String = "",
        isFavorite: Bool = false,
        drillCount: Int = 0,
        addedDate: Date = .now
    ) {
        self.name = name
        self.category = category
        self.notes = notes
        self.isFavorite = isFavorite
        self.drillCount = drillCount
        self.addedDate = addedDate
    }

    var techniqueCategory: TechniqueCategory {
        TechniqueCategory(rawValue: category) ?? .guard_
    }
}

@Model
final class BeltRecord {
    var belt: String           // BjjBelt.rawValue
    var stripes: Int
    var awardedDate: Date
    var instructor: String
    var notes: String

    init(
        belt: String,
        stripes: Int = 0,
        awardedDate: Date = .now,
        instructor: String = "",
        notes: String = ""
    ) {
        self.belt = belt
        self.stripes = stripes
        self.awardedDate = awardedDate
        self.instructor = instructor
        self.notes = notes
    }

    var bjjBelt: BjjBelt {
        BjjBelt(rawValue: belt) ?? .white
    }
}

@Model
final class Competition {
    var date: Date
    var name: String
    var weightClass: String
    var wins: Int
    var losses: Int
    var medal: Int             // 0=none, 1=bronze, 2=silver, 3=gold
    var notes: String

    init(
        date: Date = .now,
        name: String = "",
        weightClass: String = "",
        wins: Int = 0,
        losses: Int = 0,
        medal: Int = 0,
        notes: String = ""
    ) {
        self.date = date
        self.name = name
        self.weightClass = weightClass
        self.wins = wins
        self.losses = losses
        self.medal = medal
        self.notes = notes
    }

    var medalLabel: String {
        switch medal {
        case 1: return "Bronze"
        case 2: return "Silver"
        case 3: return "Gold"
        default: return "None"
        }
    }

    var medalEmoji: String {
        switch medal {
        case 1: return "🥉"
        case 2: return "🥈"
        case 3: return "🥇"
        default: return ""
        }
    }
}
