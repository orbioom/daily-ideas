import Foundation

/// The full 78-card Rider–Waite–Smith deck, embedded in code with genuine concise
/// upright and reversed interpretations. Look cards up by id with `Deck.card(id:)`.
enum Deck {
    /// All 78 cards, ordered: 22 Major (0...21), then Minor by suit (Wands, Cups, Swords,
    /// Pentacles), each Ace(1)...10, Page(11), Knight(12), Queen(13), King(14).
    static let all: [TarotCard] = major + minor

    /// O(1)-style safe lookup. Returns nil rather than trapping on an unknown id.
    static func card(id: Int) -> TarotCard? {
        byID[id]
    }

    private static let byID: [Int: TarotCard] = {
        var dict: [Int: TarotCard] = [:]
        for c in all { dict[c.id] = c }
        return dict
    }()

    static func cards(in arcana: Arcana) -> [TarotCard] {
        all.filter { $0.arcana == arcana }
    }

    static func cards(in suit: Suit) -> [TarotCard] {
        all.filter { $0.suit == suit }
    }

    // MARK: - Major Arcana (0–21)

    static let major: [TarotCard] = [
        TarotCard(id: 0, name: "The Fool", arcana: .major, suit: nil, number: 0, element: .air,
                  keywords: ["beginnings", "innocence", "spontaneity", "leap of faith"],
                  upright: "A fresh start and a leap into the unknown with open-hearted optimism. Trust the journey and let curiosity, not fear, lead the next step.",
                  reversed: "Recklessness or hesitation at the edge of a new path. Look before you leap, or stop talking yourself out of a beginning you secretly want."),
        TarotCard(id: 1, name: "The Magician", arcana: .major, suit: nil, number: 1, element: .air,
                  keywords: ["willpower", "manifestation", "skill", "focus"],
                  upright: "You already have every tool you need; aligned intention and action turn ideas into reality. Focus your will and begin.",
                  reversed: "Scattered energy, untapped talent, or manipulation. Reconnect with your true aim before your skills are wasted or misused."),
        TarotCard(id: 2, name: "The High Priestess", arcana: .major, suit: nil, number: 2, element: .water,
                  keywords: ["intuition", "mystery", "inner voice", "the unconscious"],
                  upright: "Wisdom that arrives quietly, through intuition and stillness rather than analysis. Trust what you sense beneath the surface.",
                  reversed: "Disconnection from your inner voice, or secrets kept from yourself. Stop overriding your gut with noise and second-guessing."),
        TarotCard(id: 3, name: "The Empress", arcana: .major, suit: nil, number: 3, element: .earth,
                  keywords: ["abundance", "nurturing", "creativity", "nature"],
                  upright: "Fertile, creative abundance and tender care for yourself and others. Let something grow without forcing it.",
                  reversed: "Creative block, smothering, or neglecting your own needs. Replenish before you give, and let nature take its course."),
        TarotCard(id: 4, name: "The Emperor", arcana: .major, suit: nil, number: 4, element: .fire,
                  keywords: ["authority", "structure", "stability", "leadership"],
                  upright: "Stability built through structure, boundaries, and steady leadership. Take responsibility and create order.",
                  reversed: "Rigidity, domination, or a lack of discipline. Loosen the grip, or finally provide the structure that's missing."),
        TarotCard(id: 5, name: "The Hierophant", arcana: .major, suit: nil, number: 5, element: .earth,
                  keywords: ["tradition", "guidance", "belief", "learning"],
                  upright: "Wisdom passed down through tradition, mentors, and shared belief. There is value in proven paths and trusted guidance.",
                  reversed: "Questioning convention and finding your own way. Break from dogma that no longer fits, or beware blind conformity."),
        TarotCard(id: 6, name: "The Lovers", arcana: .major, suit: nil, number: 6, element: .air,
                  keywords: ["union", "choices", "values", "harmony"],
                  upright: "Deep connection and a meaningful choice made in line with your values. Harmony comes from aligned hearts and honest commitment.",
                  reversed: "Disharmony, misalignment of values, or avoiding a choice. Address the imbalance before it widens the rift."),
        TarotCard(id: 7, name: "The Chariot", arcana: .major, suit: nil, number: 7, element: .water,
                  keywords: ["willpower", "victory", "determination", "control"],
                  upright: "Forward momentum won through discipline and focused will. Hold the reins of opposing forces and drive toward your goal.",
                  reversed: "Loss of direction or control, pulled in conflicting directions. Regain focus before scattered effort stalls you."),
        TarotCard(id: 8, name: "Strength", arcana: .major, suit: nil, number: 8, element: .fire,
                  keywords: ["courage", "patience", "compassion", "inner power"],
                  upright: "Quiet courage that tames fear through patience and compassion, not force. Your gentlest strength is your greatest.",
                  reversed: "Self-doubt, raw impulse, or depleted resolve. Be gentle with yourself and rebuild confidence from the inside."),
        TarotCard(id: 9, name: "The Hermit", arcana: .major, suit: nil, number: 9, element: .earth,
                  keywords: ["solitude", "reflection", "inner guidance", "wisdom"],
                  upright: "A time to withdraw, reflect, and let your inner light guide you. Answers come in solitude, not in the crowd.",
                  reversed: "Isolation or avoidance dressed up as soul-searching. Reconnect — too much withdrawal becomes loneliness."),
        TarotCard(id: 10, name: "Wheel of Fortune", arcana: .major, suit: nil, number: 10, element: .fire,
                  keywords: ["cycles", "fate", "turning point", "change"],
                  upright: "The wheel turns and fortune shifts; a cycle completes and a new one begins. Flow with change rather than resisting it.",
                  reversed: "A downturn, bad timing, or clinging to what's passing. Accept the cycle and stop fighting the inevitable turn."),
        TarotCard(id: 11, name: "Justice", arcana: .major, suit: nil, number: 11, element: .air,
                  keywords: ["fairness", "truth", "accountability", "cause and effect"],
                  upright: "Truth, fairness, and the clear consequences of past choices. Act with integrity and accept accountability.",
                  reversed: "Injustice, dishonesty, or avoiding responsibility. Face the truth and make things right before they compound."),
        TarotCard(id: 12, name: "The Hanged Man", arcana: .major, suit: nil, number: 12, element: .water,
                  keywords: ["surrender", "new perspective", "pause", "letting go"],
                  upright: "A meaningful pause that reveals a new perspective through surrender. Release the need to control and see things anew.",
                  reversed: "Stalling, needless martyrdom, or resisting a necessary release. Stop delaying — the lesson is in letting go."),
        TarotCard(id: 13, name: "Death", arcana: .major, suit: nil, number: 13, element: .water,
                  keywords: ["endings", "transformation", "release", "renewal"],
                  upright: "A profound ending that clears the way for transformation and renewal. Let what is finished truly end so something new can rise.",
                  reversed: "Resisting an inevitable ending, clinging to the past. Stagnation lingers until you allow the change."),
        TarotCard(id: 14, name: "Temperance", arcana: .major, suit: nil, number: 14, element: .fire,
                  keywords: ["balance", "moderation", "patience", "blending"],
                  upright: "Balance found by blending opposites with patience and moderation. Take the middle path and let things flow at their own pace.",
                  reversed: "Imbalance, excess, or impatience. Recalibrate and stop forcing what only patience can bring together."),
        TarotCard(id: 15, name: "The Devil", arcana: .major, suit: nil, number: 15, element: .earth,
                  keywords: ["attachment", "temptation", "shadow", "bondage"],
                  upright: "Bondage to habits, fears, or desires that feel inescapable but aren't. Name the chain and remember you can loosen it.",
                  reversed: "Breaking free from what has held you, reclaiming your power. Release the attachment and step out of the dark."),
        TarotCard(id: 16, name: "The Tower", arcana: .major, suit: nil, number: 16, element: .fire,
                  keywords: ["upheaval", "sudden change", "revelation", "awakening"],
                  upright: "Sudden upheaval that topples what was built on a false foundation. Painful as it is, the collapse clears the way for truth.",
                  reversed: "A disaster narrowly avoided, or clinging to crumbling structures. Let it fall — delaying only prolongs the shock."),
        TarotCard(id: 17, name: "The Star", arcana: .major, suit: nil, number: 17, element: .air,
                  keywords: ["hope", "renewal", "inspiration", "serenity"],
                  upright: "Renewed hope and calm after hardship; healing and quiet inspiration. Trust that you are guided and that brighter days follow.",
                  reversed: "Discouragement, lost faith, or disconnection from hope. Tend your inner light — it has only dimmed, not gone out."),
        TarotCard(id: 18, name: "The Moon", arcana: .major, suit: nil, number: 18, element: .water,
                  keywords: ["illusion", "intuition", "uncertainty", "the subconscious"],
                  upright: "A landscape of dreams, intuition, and uncertainty where not all is as it seems. Move slowly and trust your inner senses.",
                  reversed: "Confusion lifting, fears revealed as shadows. Clarity returns as illusions fade and truth surfaces."),
        TarotCard(id: 19, name: "The Sun", arcana: .major, suit: nil, number: 19, element: .fire,
                  keywords: ["joy", "success", "vitality", "clarity"],
                  upright: "Radiant joy, success, and warmth; clarity and vitality light your path. Celebrate openly and let your warmth shine.",
                  reversed: "Temporary clouds over your joy, or forced positivity. The sun still shines — find what's dimming your view."),
        TarotCard(id: 20, name: "Judgement", arcana: .major, suit: nil, number: 20, element: .fire,
                  keywords: ["reckoning", "awakening", "renewal", "calling"],
                  upright: "A wake-up call and honest reckoning that frees you to rise renewed. Answer the calling and forgive what's past.",
                  reversed: "Self-doubt, harsh self-judgment, or ignoring an inner call. Release guilt and listen for the invitation to begin again."),
        TarotCard(id: 21, name: "The World", arcana: .major, suit: nil, number: 21, element: .earth,
                  keywords: ["completion", "wholeness", "fulfillment", "integration"],
                  upright: "A cycle completes in fulfillment and wholeness; you have arrived. Celebrate the achievement before the next journey begins.",
                  reversed: "An unfinished chapter or a goal just out of reach. Tie up loose ends — completion is closer than it feels.")
    ]

    // MARK: - Minor Arcana

    static let minor: [TarotCard] = wands + cups + swords + pentacles
}
