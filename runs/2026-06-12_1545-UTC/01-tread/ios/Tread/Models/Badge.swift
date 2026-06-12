import Foundation
import SwiftData

/// A persisted record that a milestone badge has been earned, with the date
/// it was first unlocked. The catalog of *possible* badges is static (see
/// `BadgeCatalog`); this model only stores which ones the user has reached.
@Model
final class Badge {
    @Attribute(.unique) var key: String
    var unlockedAt: Date

    init(key: String, unlockedAt: Date) {
        self.key = key
        self.unlockedAt = unlockedAt
    }
}

/// The static catalog of achievable milestones.
struct BadgeDef: Identifiable, Hashable {
    enum Kind: Hashable {
        case singleDaySteps(Int)     // hit N steps in one day
        case streak(Int)             // N consecutive goal-met days
        case totalSteps(Int)         // lifetime cumulative steps
    }
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let kind: Kind
}

enum BadgeCatalog {
    static let all: [BadgeDef] = [
        .init(id: "day_5k",   title: "Warm Up",        detail: "5,000 steps in a day",      symbol: "figure.walk",            kind: .singleDaySteps(5_000)),
        .init(id: "day_10k",  title: "Ten Thousand",   detail: "10,000 steps in a day",     symbol: "figure.walk.motion",     kind: .singleDaySteps(10_000)),
        .init(id: "day_15k",  title: "Trailblazer",    detail: "15,000 steps in a day",     symbol: "figure.hiking",          kind: .singleDaySteps(15_000)),
        .init(id: "day_20k",  title: "Marathoner",     detail: "20,000 steps in a day",     symbol: "flame.fill",             kind: .singleDaySteps(20_000)),
        .init(id: "streak_3", title: "Three Day Spark",detail: "Hit your goal 3 days running", symbol: "bolt.fill",           kind: .streak(3)),
        .init(id: "streak_7", title: "Full Week",      detail: "A 7-day goal streak",       symbol: "calendar",               kind: .streak(7)),
        .init(id: "streak_30",title: "Iron Month",     detail: "A 30-day goal streak",      symbol: "shield.fill",            kind: .streak(30)),
        .init(id: "total_100k",title: "Six Figures",   detail: "100,000 steps logged",      symbol: "star.fill",              kind: .totalSteps(100_000)),
        .init(id: "total_500k",title: "Half Million",  detail: "500,000 steps logged",      symbol: "crown.fill",             kind: .totalSteps(500_000)),
        .init(id: "total_1m", title: "Millionaire",    detail: "1,000,000 steps logged",    symbol: "trophy.fill",            kind: .totalSteps(1_000_000)),
    ]

    static func def(for id: String) -> BadgeDef? { all.first { $0.id == id } }
}
