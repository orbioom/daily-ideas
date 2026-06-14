import Foundation
import SwiftData

@Model
final class Preset {
    @Attribute(.unique) var id: UUID
    var name: String
    /// 0 = open-ended.
    var durationMin: Int
    var warmupSec: Int
    /// 0 = no interval bells.
    var intervalMin: Int
    /// Raw value of `Ambient`.
    var ambient: String
    /// Raw value of `BellTone`.
    var bellSound: String
    var isBuiltIn: Bool
    var sortOrder: Int

    init(id: UUID = UUID(),
         name: String,
         durationMin: Int,
         warmupSec: Int,
         intervalMin: Int,
         ambient: Ambient,
         bellSound: BellTone,
         isBuiltIn: Bool,
         sortOrder: Int) {
        self.id = id
        self.name = name
        self.durationMin = durationMin
        self.warmupSec = warmupSec
        self.intervalMin = intervalMin
        self.ambient = ambient.rawValue
        self.bellSound = bellSound.rawValue
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
    }

    // MARK: - Typed accessors
    var ambientValue: Ambient {
        get { Ambient(rawValue: ambient) ?? .none }
        set { ambient = newValue.rawValue }
    }

    var bellValue: BellTone {
        get { BellTone(rawValue: bellSound) ?? .bowl }
        set { bellSound = newValue.rawValue }
    }

    var isOpenEnded: Bool { durationMin == 0 }

    var subtitle: String {
        var parts: [String] = []
        parts.append(isOpenEnded ? "Open" : "\(durationMin) min")
        if warmupSec > 0 { parts.append("\(warmupSec)s warmup") }
        if intervalMin > 0 { parts.append("bell every \(intervalMin) min") }
        if ambientValue != .none { parts.append(ambientValue.displayName) }
        return parts.joined(separator: " · ")
    }
}
