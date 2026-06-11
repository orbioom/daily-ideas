import Foundation
import SwiftData

enum AssignmentStatus: String, Codable, CaseIterable {
    case pending   = "Pending"
    case submitted = "Submitted"
    case graded    = "Graded"

    var icon: String {
        switch self {
        case .pending:   return "circle"
        case .submitted: return "arrow.up.circle.fill"
        case .graded:    return "checkmark.circle.fill"
        }
    }
}

enum GradingScale: String, Codable, CaseIterable {
    case standard   = "Letter (A–F)"
    case plusMinus  = "A+/A/A-…"
    case passFail   = "Pass/Fail"
}

@Model
final class AcademicTerm {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var isActive: Bool

    @Relationship(deleteRule: .cascade, inverse: \Course.term)
    var courses: [Course]

    init(name: String, startDate: Date, endDate: Date) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = true
        self.courses = []
    }

    var gpa: Double {
        let eligible = courses.filter { !$0.assignments.isEmpty }
        guard !eligible.isEmpty else { return 0 }
        let totalPoints = eligible.reduce(0.0) { sum, c in
            let grade = c.currentGrade
            return sum + GPACalculator.gradeToPoints(grade) * c.credits
        }
        let totalCredits = eligible.reduce(0.0) { $0 + $1.credits }
        return totalCredits > 0 ? totalPoints / totalCredits : 0
    }
}

@Model
final class Course {
    var id: UUID
    var name: String
    var code: String
    var instructor: String
    var colorHex: String
    var credits: Double
    var gradingScaleRaw: String
    var term: AcademicTerm?

    @Relationship(deleteRule: .cascade, inverse: \GradeWeight.course)
    var weights: [GradeWeight]

    @Relationship(deleteRule: .cascade, inverse: \Assignment.course)
    var assignments: [Assignment]

    @Relationship(deleteRule: .cascade, inverse: \ClassSchedule.course)
    var schedule: [ClassSchedule]

    init(name: String, code: String, instructor: String = "", colorHex: String = "#5C6BC0", credits: Double = 3.0) {
        self.id = UUID()
        self.name = name
        self.code = code
        self.instructor = instructor
        self.colorHex = colorHex
        self.credits = credits
        self.gradingScaleRaw = GradingScale.standard.rawValue
        self.weights = []
        self.assignments = []
        self.schedule = []
    }

    var gradingScale: GradingScale { GradingScale(rawValue: gradingScaleRaw) ?? .standard }

    var currentGrade: Double {
        GPACalculator.computeGrade(weights: weights, assignments: assignments)
    }

    var letterGrade: String {
        GPACalculator.pointsToLetter(currentGrade)
    }
}

@Model
final class GradeWeight {
    var category: String
    var weight: Double
    var course: Course?

    init(category: String, weight: Double) {
        self.category = category
        self.weight = weight
    }
}

@Model
final class Assignment {
    var id: UUID
    var name: String
    var category: String
    var dueDate: Date
    var statusRaw: String
    var maxPoints: Double
    var earnedPoints: Double
    var notes: String
    var course: Course?

    init(name: String, category: String, dueDate: Date, maxPoints: Double = 100) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.dueDate = dueDate
        self.statusRaw = AssignmentStatus.pending.rawValue
        self.maxPoints = maxPoints
        self.earnedPoints = 0
        self.notes = ""
    }

    var status: AssignmentStatus { AssignmentStatus(rawValue: statusRaw) ?? .pending }

    var percentage: Double? {
        guard status == .graded && maxPoints > 0 else { return nil }
        return (earnedPoints / maxPoints) * 100
    }

    var isOverdue: Bool {
        status == .pending && dueDate < Date()
    }

    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }
}

@Model
final class ClassSchedule {
    var weekday: Int  // 1=Sun...7=Sat (Calendar.current.component(.weekday))
    var startTime: Date
    var endTime: Date
    var location: String
    var course: Course?

    init(weekday: Int, startTime: Date, endTime: Date, location: String = "") {
        self.weekday = weekday
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
    }

    var weekdayName: String {
        let symbols = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return weekday > 0 && weekday <= 7 ? symbols[weekday] : "?"
    }
}

struct GPACalculator {
    static func gradeToPoints(_ pct: Double) -> Double {
        switch pct {
        case 93...: return 4.0
        case 90..<93: return 3.7
        case 87..<90: return 3.3
        case 83..<87: return 3.0
        case 80..<83: return 2.7
        case 77..<80: return 2.3
        case 73..<77: return 2.0
        case 70..<73: return 1.7
        case 67..<70: return 1.3
        case 63..<67: return 1.0
        case 60..<63: return 0.7
        default: return 0.0
        }
    }

    static func pointsToLetter(_ pct: Double) -> String {
        switch pct {
        case 93...: return "A"
        case 90..<93: return "A-"
        case 87..<90: return "B+"
        case 83..<87: return "B"
        case 80..<83: return "B-"
        case 77..<80: return "C+"
        case 73..<77: return "C"
        case 70..<73: return "C-"
        case 67..<70: return "D+"
        case 63..<67: return "D"
        case 60..<63: return "D-"
        default: return "F"
        }
    }

    static func gradeColor(_ pct: Double) -> String {
        switch pct {
        case 90...: return "green"
        case 80..<90: return "blue"
        case 70..<80: return "yellow"
        case 60..<70: return "orange"
        default: return "red"
        }
    }

    static func computeGrade(weights: [GradeWeight], assignments: [Assignment]) -> Double {
        guard !weights.isEmpty else {
            let graded = assignments.filter { $0.status == .graded && $0.maxPoints > 0 }
            guard !graded.isEmpty else { return 0 }
            let total = graded.reduce(0.0) { $0 + ($1.earnedPoints / $1.maxPoints * 100) }
            return total / Double(graded.count)
        }
        var weighted = 0.0
        var usedWeight = 0.0
        for w in weights {
            let items = assignments.filter { $0.category == w.category && $0.status == .graded && $0.maxPoints > 0 }
            guard !items.isEmpty else { continue }
            let avg = items.reduce(0.0) { $0 + $1.earnedPoints / $1.maxPoints * 100 } / Double(items.count)
            weighted += avg * w.weight
            usedWeight += w.weight
        }
        return usedWeight > 0 ? weighted / usedWeight : 0
    }

    static func neededToAchieve(target: Double, current: Double, currentWeight: Double, remainingWeight: Double) -> Double {
        guard remainingWeight > 0 else { return 0 }
        return (target - current * currentWeight / 100.0) / (remainingWeight / 100.0)
    }
}
