import Foundation
import SwiftData

@Model
final class WODResult {
    var date: Date
    var wodName: String
    var wodType: String
    var movements: String
    var timeSeconds: Int
    var rounds: Int
    var reps: Int
    var notes: String
    var rx: Bool
    var scaled: Bool
    var rating: Int

    init(
        date: Date = .now,
        wodName: String = "",
        wodType: String = WODType.forTime.rawValue,
        movements: String = "",
        timeSeconds: Int = 0,
        rounds: Int = 0,
        reps: Int = 0,
        notes: String = "",
        rx: Bool = true,
        scaled: Bool = false,
        rating: Int = 3
    ) {
        self.date = date
        self.wodName = wodName
        self.wodType = wodType
        self.movements = movements
        self.timeSeconds = timeSeconds
        self.rounds = rounds
        self.reps = reps
        self.notes = notes
        self.rx = rx
        self.scaled = scaled
        self.rating = rating
    }

    var formattedTime: String {
        guard timeSeconds > 0 else { return "—" }
        let m = timeSeconds / 60
        let s = timeSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var scoreDisplay: String {
        let t = WODType(rawValue: wodType) ?? .forTime
        switch t {
        case .amrap: return "\(rounds) rds + \(reps) reps"
        case .forTime: return formattedTime
        case .emom: return "\(rounds) rounds completed"
        case .tabata: return "\(rounds) rounds"
        default: return timeSeconds > 0 ? formattedTime : "\(rounds) rds"
        }
    }
}

@Model
final class PersonalRecord {
    var movement: String
    var weight: Double
    var unit: String
    var date: Date
    var notes: String
    var category: String

    init(
        movement: String = "",
        weight: Double = 0,
        unit: String = "lb",
        notes: String = "",
        category: String = MovementCategory.weightlifting.rawValue
    ) {
        self.movement = movement
        self.weight = weight
        self.unit = unit
        self.date = Date()
        self.notes = notes
        self.category = category
    }

    var display: String {
        "\(Int(weight)) \(unit)"
    }
}

@Model
final class KataSettings {
    var hasCompletedOnboarding: Bool
    var weightUnit: String
    var isPro: Bool
    var boxName: String
    var hapticsEnabled: Bool
    var showDailyWOD: Bool

    init() {
        self.hasCompletedOnboarding = false
        self.weightUnit = "lb"
        self.isPro = false
        self.boxName = ""
        self.hapticsEnabled = true
        self.showDailyWOD = true
    }
}

struct BuiltInWOD: Identifiable {
    let id = UUID()
    let name: String
    let type: WODType
    let description: String
    let movements: [String]
    let timeCap: Int?
    let isHero: Bool

    static let all: [BuiltInWOD] = [
        BuiltInWOD(name: "Fran", type: .forTime, description: "21-15-9 Thrusters & Pull-ups",
                   movements: ["21 Thrusters (95/65 lb)", "21 Pull-ups", "15 Thrusters", "15 Pull-ups", "9 Thrusters", "9 Pull-ups"], timeCap: nil, isHero: false),
        BuiltInWOD(name: "Cindy", type: .amrap, description: "20 min AMRAP",
                   movements: ["5 Pull-ups", "10 Push-ups", "15 Air Squats"], timeCap: 1200, isHero: false),
        BuiltInWOD(name: "Murph", type: .forTime, description: "Hero WOD — wear a 20 lb vest",
                   movements: ["1 mile Run", "100 Pull-ups", "200 Push-ups", "300 Air Squats", "1 mile Run"], timeCap: nil, isHero: true),
        BuiltInWOD(name: "Grace", type: .forTime, description: "30 Clean & Jerks for time",
                   movements: ["30 Clean & Jerks (135/95 lb)"], timeCap: nil, isHero: false),
        BuiltInWOD(name: "Isabel", type: .forTime, description: "30 Snatches for time",
                   movements: ["30 Snatches (135/95 lb)"], timeCap: nil, isHero: false),
        BuiltInWOD(name: "Helen", type: .forTime, description: "3 rounds for time",
                   movements: ["400m Run", "21 Kettlebell Swings (53/35 lb)", "12 Pull-ups"], timeCap: nil, isHero: false),
        BuiltInWOD(name: "Annie", type: .forTime, description: "50-40-30-20-10",
                   movements: ["Double-unders", "Sit-ups"], timeCap: nil, isHero: false),
        BuiltInWOD(name: "DT", type: .forTime, description: "5 rounds for time",
                   movements: ["12 Deadlifts (155/105 lb)", "9 Hang Power Cleans", "6 Push Jerks"], timeCap: nil, isHero: true),
        BuiltInWOD(name: "Chelsea", type: .emom, description: "30-min EMOM",
                   movements: ["5 Pull-ups", "10 Push-ups", "15 Air Squats"], timeCap: 1800, isHero: false),
        BuiltInWOD(name: "Barbara", type: .forTime, description: "5 rounds, 3 min rest",
                   movements: ["20 Pull-ups", "30 Push-ups", "40 Sit-ups", "50 Air Squats", "(3 min rest)"], timeCap: nil, isHero: false),
        BuiltInWOD(name: "Diane", type: .forTime, description: "21-15-9",
                   movements: ["Deadlifts (225/155 lb)", "Handstand Push-ups"], timeCap: nil, isHero: false),
        BuiltInWOD(name: "Elizabeth", type: .forTime, description: "21-15-9",
                   movements: ["Clean (135/95 lb)", "Ring Dips"], timeCap: nil, isHero: false),
    ]
}

let commonMovements = [
    "Air Squat", "Back Squat", "Front Squat", "Overhead Squat",
    "Deadlift", "Sumo Deadlift High Pull",
    "Clean", "Power Clean", "Hang Power Clean", "Clean & Jerk",
    "Snatch", "Power Snatch", "Hang Power Snatch",
    "Thruster", "Push Press", "Push Jerk", "Split Jerk",
    "Overhead Press", "Bench Press",
    "Pull-up", "Chest-to-Bar Pull-up", "Muscle-up (Bar)", "Muscle-up (Ring)",
    "Push-up", "Handstand Push-up", "Pike Push-up",
    "Toes-to-Bar", "Knees-to-Elbows", "Sit-up", "GHD Sit-up",
    "Box Jump", "Burpee", "Burpee Box Jump",
    "Kettlebell Swing (Russian)", "Kettlebell Swing (American)",
    "Row (cal)", "Bike (cal)", "Ski Erg (cal)",
    "Double-under", "Single-under",
    "Run 400m", "Run 800m", "Run 1 mile",
    "Rope Climb", "Legless Rope Climb",
    "Ring Row", "Ring Dip",
    "Wall Ball", "Med Ball Clean",
    "Dumbbell Snatch", "Dumbbell Thruster",
]
