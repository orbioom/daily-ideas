import Foundation
import SwiftData

/// Seeds a bestiary, a ready-to-run encounter, and a little dice history.
enum SampleData {
    static func seed(into context: ModelContext) {
        let blocks: [(String, CombatantSide, Int, Int, Int, String)] = [
            ("Goblin", .enemy, 7, 15, 2, "Nimble Escape: disengage/hide as bonus action."),
            ("Hobgoblin", .enemy, 11, 18, 1, "Martial Advantage: +2d6 once per turn."),
            ("Dire Wolf", .enemy, 37, 14, 2, "Pack tactics; knock prone on hit (DC 13)."),
            ("Bandit Captain", .enemy, 65, 15, 2, "Multiattack; Parry reaction."),
            ("Acolyte", .ally, 9, 10, 0, "Cure Wounds, Sacred Flame."),
        ]
        for b in blocks {
            context.insert(StatBlock(name: b.0, side: b.1, maxHP: b.2, armorClass: b.3, initiativeMod: b.4, notes: b.5))
        }

        let enc = Encounter(name: "Ambush at the Ford", notes: "Goblins spring from the reeds.")
        context.insert(enc)
        let party: [(String, Int, Int, Int)] = [
            ("Thereon (Fighter)", 32, 18, 1),
            ("Mirella (Wizard)", 18, 12, 3),
            ("Brakk (Cleric)", 27, 16, 0),
        ]
        for p in party {
            let c = Combatant(name: p.0, side: .pc, maxHP: p.1, armorClass: p.2, initiativeMod: p.3)
            c.initiative = Int.random(in: 1...20) + p.3
            enc.combatants.append(c)
        }
        for _ in 0..<3 {
            let g = Combatant(name: "Goblin", side: .enemy, maxHP: 7, armorClass: 15, initiativeMod: 2)
            g.initiative = Int.random(in: 1...20) + 2
            enc.combatants.append(g)
        }

        let r1 = Dice.roll("2d6+3")
        if let r1 { context.insert(DiceLog(expression: r1.expression, total: r1.total, breakdown: r1.breakdown, label: "Damage")) }
        let r2 = Dice.roll("1d20+5")
        if let r2 { context.insert(DiceLog(expression: r2.expression, total: r2.total, breakdown: r2.breakdown, label: "Attack")) }
    }
}
