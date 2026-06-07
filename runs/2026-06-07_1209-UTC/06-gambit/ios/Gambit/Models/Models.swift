import Foundation
import SwiftData

/// Standard 5e-style conditions a combatant can carry.
enum Condition: String, CaseIterable, Identifiable {
    case blinded = "Blinded"
    case charmed = "Charmed"
    case deafened = "Deafened"
    case frightened = "Frightened"
    case grappled = "Grappled"
    case incapacitated = "Incapacitated"
    case invisible = "Invisible"
    case paralyzed = "Paralyzed"
    case poisoned = "Poisoned"
    case prone = "Prone"
    case restrained = "Restrained"
    case stunned = "Stunned"
    case unconscious = "Unconscious"
    case concentrating = "Concentrating"
    var id: String { rawValue }
    var short: String { String(rawValue.prefix(4)) }
}

/// The role of a participant — drives colour and default behaviour.
enum CombatantSide: String, CaseIterable, Identifiable {
    case pc = "Player"
    case ally = "Ally"
    case enemy = "Enemy"
    var id: String { rawValue }
}

/// A reusable stat block in the bestiary that can be dropped into encounters.
@Model
final class StatBlock {
    var id: UUID = UUID()
    var name: String = ""
    var sideRaw: String = CombatantSide.enemy.rawValue
    var maxHP: Int = 10
    var armorClass: Int = 12
    var initiativeMod: Int = 0
    var notes: String = ""
    var createdAt: Date = Date()

    init(name: String, side: CombatantSide = .enemy, maxHP: Int = 10,
         armorClass: Int = 12, initiativeMod: Int = 0, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.sideRaw = side.rawValue
        self.maxHP = max(1, maxHP)
        self.armorClass = max(0, armorClass)
        self.initiativeMod = initiativeMod
        self.notes = notes
        self.createdAt = Date()
    }
    var side: CombatantSide {
        get { CombatantSide(rawValue: sideRaw) ?? .enemy }
        set { sideRaw = newValue.rawValue }
    }
}

/// A combat encounter owning its combatants, with round and turn state.
@Model
final class Encounter {
    var id: UUID = UUID()
    var name: String = ""
    var round: Int = 0          // 0 = not started
    var activeIndex: Int = 0
    var notes: String = ""
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \Combatant.encounter)
    var combatants: [Combatant] = []

    init(name: String, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.notes = notes
        self.createdAt = Date()
    }

    /// Combatants in initiative order (desc), tie-break by mod then name.
    var ordered: [Combatant] {
        combatants.sorted {
            if $0.initiative != $1.initiative { return $0.initiative > $1.initiative }
            if $0.initiativeMod != $1.initiativeMod { return $0.initiativeMod > $1.initiativeMod }
            return $0.name < $1.name
        }
    }
    var started: Bool { round > 0 }
    var aliveEnemies: Int { combatants.filter { $0.side == .enemy && $0.currentHP > 0 }.count }
    var aliveAllies: Int { combatants.filter { $0.side != .enemy && $0.currentHP > 0 }.count }
}

/// A participant in an encounter.
@Model
final class Combatant {
    var id: UUID = UUID()
    var name: String = ""
    var sideRaw: String = CombatantSide.enemy.rawValue
    var initiative: Int = 0
    var initiativeMod: Int = 0
    var maxHP: Int = 10
    var currentHP: Int = 10
    var tempHP: Int = 0
    var armorClass: Int = 12
    var conditionsRaw: String = ""
    var notes: String = ""
    var encounter: Encounter?

    init(name: String, side: CombatantSide = .enemy, maxHP: Int = 10,
         armorClass: Int = 12, initiativeMod: Int = 0) {
        self.id = UUID()
        self.name = name
        self.sideRaw = side.rawValue
        self.maxHP = max(1, maxHP)
        self.currentHP = max(1, maxHP)
        self.armorClass = max(0, armorClass)
        self.initiativeMod = initiativeMod
    }

    var side: CombatantSide {
        get { CombatantSide(rawValue: sideRaw) ?? .enemy }
        set { sideRaw = newValue.rawValue }
    }
    var conditions: Set<Condition> {
        get {
            Set(conditionsRaw.split(separator: ",").compactMap { Condition(rawValue: String($0)) })
        }
        set {
            conditionsRaw = newValue.map { $0.rawValue }.sorted().joined(separator: ",")
        }
    }
    var isDown: Bool { currentHP <= 0 }
    var hpFraction: Double { maxHP > 0 ? Double(max(0, currentHP)) / Double(maxHP) : 0 }

    /// Apply damage: temp HP soaks first.
    func takeDamage(_ amount: Int) {
        var dmg = max(0, amount)
        if tempHP > 0 {
            let absorbed = min(tempHP, dmg)
            tempHP -= absorbed
            dmg -= absorbed
        }
        currentHP = max(0, currentHP - dmg)
    }
    func heal(_ amount: Int) {
        guard amount > 0 else { return }
        currentHP = min(maxHP, currentHP + amount)
    }
}
