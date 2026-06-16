import Foundation
import SwiftData

/// A child profile. Multiple profiles require Digit Pro (free = 1).
@Model
final class Profile {
    @Attribute(.unique) var id: UUID
    var name: String
    var avatarEmoji: String
    var createdDate: Date
    var currentLevelIndex: Int
    var maxNumber: Int

    // Enabled operations stored as discrete booleans (SwiftData-friendly, no set transformer).
    var opAddEnabled: Bool
    var opSubEnabled: Bool
    var opMulEnabled: Bool
    var opDivEnabled: Bool

    @Relationship(deleteRule: .cascade, inverse: \FactStat.profile)
    var facts: [FactStat]

    @Relationship(deleteRule: .cascade, inverse: \Session.profile)
    var sessions: [Session]

    init(name: String,
         avatarEmoji: String = "🦊",
         createdDate: Date = .now,
         currentLevelIndex: Int = 0,
         maxNumber: Int = 10,
         enabledOps: Set<MathOp> = [.add, .sub]) {
        self.id = UUID()
        self.name = name
        self.avatarEmoji = avatarEmoji
        self.createdDate = createdDate
        self.currentLevelIndex = currentLevelIndex
        self.maxNumber = maxNumber
        self.opAddEnabled = enabledOps.contains(.add)
        self.opSubEnabled = enabledOps.contains(.sub)
        self.opMulEnabled = enabledOps.contains(.mul)
        self.opDivEnabled = enabledOps.contains(.div)
        self.facts = []
        self.sessions = []
    }

    var enabledOps: Set<MathOp> {
        var s = Set<MathOp>()
        if opAddEnabled { s.insert(.add) }
        if opSubEnabled { s.insert(.sub) }
        if opMulEnabled { s.insert(.mul) }
        if opDivEnabled { s.insert(.div) }
        return s
    }

    func setOp(_ op: MathOp, enabled: Bool) {
        switch op {
        case .add: opAddEnabled = enabled
        case .sub: opSubEnabled = enabled
        case .mul: opMulEnabled = enabled
        case .div: opDivEnabled = enabled
        }
    }
}
