import Foundation
import SwiftData

/// Seeds a few dreams, dream signs and one lucid dream so the journal, signs
/// list and insights are alive on first launch.
enum SeedData {
    @MainActor
    static func installIfNeeded(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Dream>())) ?? 0
        guard count == 0 else { return }
        let cal = Calendar.current

        let flying = DreamSign(name: "Flying", category: .action)
        let oldSchool = DreamSign(name: "My old school", category: .place)
        let teeth = DreamSign(name: "Losing teeth", category: .theme)
        let water = DreamSign(name: "Ocean / water", category: .place)
        let chased = DreamSign(name: "Being chased", category: .action)
        [flying, oldSchool, teeth, water, chased].forEach { context.insert($0) }

        struct Spec {
            let day: Int; let title: String; let text: String
            let lucid: Lucidity; let vivid: Int; let mood: DreamMood
            let nightmare: Bool; let recurring: Bool; let tech: DreamTechnique; let signs: [DreamSign]
        }

        let specs: [Spec] = [
            .init(day: 1, title: "The endless corridor", text: "I wandered the halls of my old school, but the corridors kept stretching. Every door opened onto another hallway. I felt I'd been here before.", lucid: .nonLucid, vivid: 4, mood: .strange, nightmare: false, recurring: true, tech: .journaling, signs: [oldSchool]),
            .init(day: 2, title: "Over the bay", text: "I realized I could lift off the ground. I rose over a glittering bay and the wind was warm. Somehow I knew it wasn't real — and then I was steering.", lucid: .lucid, vivid: 5, mood: .joyful, nightmare: false, recurring: false, tech: .mild, signs: [flying, water]),
            .init(day: 3, title: "Fragments", text: "Only pieces left. A train platform. Someone calling my name. A feeling of being late.", lucid: .nonLucid, vivid: 2, mood: .anxious, nightmare: false, recurring: false, tech: .none, signs: []),
            .init(day: 4, title: "The tide came in", text: "Standing on the shore as the ocean rose higher than the buildings. Not scared exactly — awed.", lucid: .semiLucid, vivid: 4, mood: .strange, nightmare: false, recurring: false, tech: .realityCheck, signs: [water]),
            .init(day: 6, title: "Footsteps behind", text: "Someone was following me through a night market. I couldn't run fast enough. I woke with my heart pounding.", lucid: .nonLucid, vivid: 4, mood: .scary, nightmare: true, recurring: true, tech: .none, signs: [chased]),
            .init(day: 8, title: "Lucid again", text: "I checked my hands — six fingers. I knew instantly. I asked the dream to show me something beautiful and a garden bloomed around me.", lucid: .lucid, vivid: 5, mood: .peaceful, nightmare: false, recurring: false, tech: .wbtb, signs: [flying]),
            .init(day: 11, title: "School reunion", text: "Back at the old school, but everyone was a stranger. My teeth felt loose and I kept checking them.", lucid: .nonLucid, vivid: 3, mood: .anxious, nightmare: false, recurring: true, tech: .none, signs: [oldSchool, teeth]),
        ]

        for s in specs {
            let dream = Dream(date: cal.date(byAdding: .day, value: -s.day, to: Date()) ?? Date(),
                              title: s.title, narrative: s.text, lucidity: s.lucid, vividness: s.vivid,
                              mood: s.mood, isNightmare: s.nightmare, isRecurring: s.recurring, technique: s.tech)
            context.insert(dream)
            dream.signs = s.signs
        }
        try? context.save()
    }
}
