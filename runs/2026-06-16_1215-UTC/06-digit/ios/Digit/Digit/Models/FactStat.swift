import Foundation
import SwiftData

/// One arithmetic fact's learning record. Identity = op + a + b.
@Model
final class FactStat {
    @Attribute(.unique) var id: UUID
    var opRaw: String
    var a: Int
    var b: Int
    var timesSeen: Int
    var timesCorrect: Int
    var fastestMs: Int?
    var lastSeen: Date?
    /// 0 = new, 1 = learning, 2 = almost, 3 = mastered.
    var masteryLevel: Int

    var profile: Profile?

    init(op: MathOp, a: Int, b: Int) {
        self.id = UUID()
        self.opRaw = op.rawValue
        self.a = a
        self.b = b
        self.timesSeen = 0
        self.timesCorrect = 0
        self.fastestMs = nil
        self.lastSeen = nil
        self.masteryLevel = 0
    }

    var op: MathOp { MathOp(rawValue: opRaw) ?? .add }

    /// The correct answer for this fact (guarded against impossible inputs).
    var answer: Int {
        switch op {
        case .add: return a + b
        case .sub: return a - b
        case .mul: return a * b
        case .div: return b == 0 ? a : a / b
        }
    }

    var prompt: String { "\(a) \(op.symbol) \(b)" }

    var accuracy: Double {
        timesSeen > 0 ? Double(timesCorrect) / Double(timesSeen) : 0
    }

    /// A stable key uniquely identifying this fact's identity.
    var identityKey: String { "\(opRaw)-\(a)-\(b)" }
}
