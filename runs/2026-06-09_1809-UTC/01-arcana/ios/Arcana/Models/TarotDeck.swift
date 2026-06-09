import Foundation

/// The arcana a card belongs to.
enum Arcana: String, CaseIterable, Identifiable {
    case major, minor
    var id: String { rawValue }
    var title: String {
        switch self {
        case .major: return "Major Arcana"
        case .minor: return "Minor Arcana"
        }
    }
}

/// The four suits of the Minor Arcana.
enum Suit: String, CaseIterable, Identifiable {
    case wands, cups, swords, pentacles
    var id: String { rawValue }
    var title: String {
        switch self {
        case .wands: return "Wands"
        case .cups: return "Cups"
        case .swords: return "Swords"
        case .pentacles: return "Pentacles"
        }
    }
    var element: String {
        switch self {
        case .wands: return "Fire"
        case .cups: return "Water"
        case .swords: return "Air"
        case .pentacles: return "Earth"
        }
    }
    var symbol: String {
        switch self {
        case .wands: return "flame.fill"
        case .cups: return "drop.fill"
        case .swords: return "wind"
        case .pentacles: return "circle.hexagongrid.fill"
        }
    }
}

/// A single, immutable tarot card from the Rider–Waite deck. This is static
/// reference data (not SwiftData) — the full 78-card deck is the core catalog.
struct TarotCard: Identifiable, Hashable {
    let id: Int
    let name: String
    let arcana: Arcana
    let suit: Suit?
    let number: Int
    let upright: [String]
    let reversed: [String]
    let uprightMeaning: String
    let reversedMeaning: String
    let element: String
    let symbol: String

    func keywords(reversed isReversed: Bool) -> [String] {
        isReversed ? reversed : upright
    }
    func meaning(reversed isReversed: Bool) -> String {
        isReversed ? reversedMeaning : uprightMeaning
    }
}

/// The full Rider–Waite tarot deck: 22 Major Arcana + 56 Minor Arcana.
enum TarotDeck {
    static func card(id: Int) -> TarotCard? { byID[id] }

    private static let byID: [Int: TarotCard] = {
        var map: [Int: TarotCard] = [:]
        for c in all { map[c.id] = c }
        return map
    }()

    static let major: [TarotCard] = all.filter { $0.arcana == .major }
    static func minor(_ suit: Suit) -> [TarotCard] { all.filter { $0.suit == suit } }

    static let all: [TarotCard] = majorArcana + suitCards(.wands, base: 22)
        + suitCards(.cups, base: 36) + suitCards(.swords, base: 50) + suitCards(.pentacles, base: 64)

    // MARK: - Major Arcana (ids 0…21)
    private static let majorArcana: [TarotCard] = [
        TarotCard(id: 0, name: "The Fool", arcana: .major, suit: nil, number: 0,
                  upright: ["Beginnings", "Innocence", "Spontaneity", "Free spirit"],
                  reversed: ["Recklessness", "Naivety", "Risk-taking", "Holding back"],
                  uprightMeaning: "A leap of faith into the unknown, carried by curiosity and trust. The world is wide open and anything is possible.",
                  reversedMeaning: "A reckless plunge or, conversely, fear that keeps you frozen at the edge. Look before you leap.",
                  element: "Air", symbol: "figure.walk"),
        TarotCard(id: 1, name: "The Magician", arcana: .major, suit: nil, number: 1,
                  upright: ["Manifestation", "Willpower", "Skill", "Resourcefulness"],
                  reversed: ["Manipulation", "Untapped talent", "Trickery", "Poor planning"],
                  uprightMeaning: "You have every tool you need to make your vision real. Focused will turns intention into action.",
                  reversedMeaning: "Talent left idle, or power used to deceive. Realign your means with honest ends.",
                  element: "Air", symbol: "wand.and.stars"),
        TarotCard(id: 2, name: "The High Priestess", arcana: .major, suit: nil, number: 2,
                  upright: ["Intuition", "Mystery", "Inner voice", "The subconscious"],
                  reversed: ["Secrets", "Disconnection", "Withdrawal", "Silence ignored"],
                  uprightMeaning: "A call to listen inward, where quiet knowing lives. Trust the wisdom beneath the surface.",
                  reversedMeaning: "You may be ignoring your intuition or keeping vital truths hidden. Reconnect with your inner voice.",
                  element: "Water", symbol: "moon.stars.fill"),
        TarotCard(id: 3, name: "The Empress", arcana: .major, suit: nil, number: 3,
                  upright: ["Abundance", "Nurturing", "Creativity", "Fertility"],
                  reversed: ["Dependence", "Smothering", "Creative block", "Neglect"],
                  uprightMeaning: "Life flourishes through care, beauty, and creative generosity. Nurture what you wish to see grow.",
                  reversedMeaning: "Over-giving, blocked creativity, or self-neglect. Tend to your own garden too.",
                  element: "Earth", symbol: "leaf.fill"),
        TarotCard(id: 4, name: "The Emperor", arcana: .major, suit: nil, number: 4,
                  upright: ["Authority", "Structure", "Stability", "Leadership"],
                  reversed: ["Rigidity", "Domination", "Lack of discipline", "Control"],
                  uprightMeaning: "Order and steady leadership build lasting foundations. Set boundaries and lead with reason.",
                  reversedMeaning: "Control hardens into rigidity, or structure collapses into chaos. Find the firm-but-fair middle.",
                  element: "Fire", symbol: "shield.fill"),
        TarotCard(id: 5, name: "The Hierophant", arcana: .major, suit: nil, number: 5,
                  upright: ["Tradition", "Guidance", "Belief systems", "Conformity"],
                  reversed: ["Rebellion", "Unconventionality", "Dogma questioned", "Freedom"],
                  uprightMeaning: "Wisdom passed down through tradition, mentors, and shared belief. There is value in established paths.",
                  reversedMeaning: "A break from convention or a challenge to inherited rules. Forge your own meaning.",
                  element: "Earth", symbol: "building.columns.fill"),
        TarotCard(id: 6, name: "The Lovers", arcana: .major, suit: nil, number: 6,
                  upright: ["Union", "Choices", "Harmony", "Values aligned"],
                  reversed: ["Disharmony", "Imbalance", "Misalignment", "Indecision"],
                  uprightMeaning: "A meaningful union and a choice made from the heart's true values. Connection and alignment.",
                  reversedMeaning: "Conflict between head and heart, or a bond out of balance. Clarify what you truly value.",
                  element: "Air", symbol: "heart.fill"),
        TarotCard(id: 7, name: "The Chariot", arcana: .major, suit: nil, number: 7,
                  upright: ["Willpower", "Determination", "Victory", "Control"],
                  reversed: ["Lack of direction", "Aggression", "Scattered", "Obstacles"],
                  uprightMeaning: "Drive and discipline carry you to victory. Hold the reins of opposing forces and move forward.",
                  reversedMeaning: "Momentum stalls or scatters. Refocus your direction and steady your inner conflict.",
                  element: "Water", symbol: "car.fill"),
        TarotCard(id: 8, name: "Strength", arcana: .major, suit: nil, number: 8,
                  upright: ["Courage", "Compassion", "Inner strength", "Patience"],
                  reversed: ["Self-doubt", "Weakness", "Insecurity", "Force"],
                  uprightMeaning: "True power is gentle. Courage and compassion tame what fear cannot. Quiet resolve wins.",
                  reversedMeaning: "Self-doubt or raw force undermines you. Reconnect with your calm inner strength.",
                  element: "Fire", symbol: "infinity"),
        TarotCard(id: 9, name: "The Hermit", arcana: .major, suit: nil, number: 9,
                  upright: ["Introspection", "Solitude", "Inner guidance", "Searching"],
                  reversed: ["Isolation", "Loneliness", "Withdrawal", "Lost"],
                  uprightMeaning: "A turn inward to seek truth by your own light. Solitude reveals what noise conceals.",
                  reversedMeaning: "Solitude curdles into isolation, or you avoid needed reflection. Seek balance and connection.",
                  element: "Earth", symbol: "lantern.fill"),
        TarotCard(id: 10, name: "Wheel of Fortune", arcana: .major, suit: nil, number: 10,
                  upright: ["Cycles", "Change", "Fate", "Turning point"],
                  reversed: ["Bad luck", "Resistance", "Setbacks", "Breaking cycles"],
                  uprightMeaning: "The wheel turns and fortune shifts. Ride the cycle; what rises will fall and rise again.",
                  reversedMeaning: "A run of setbacks or clinging to what's passing. Accept change and break the loop.",
                  element: "Fire", symbol: "circle.dashed"),
        TarotCard(id: 11, name: "Justice", arcana: .major, suit: nil, number: 11,
                  upright: ["Fairness", "Truth", "Cause and effect", "Accountability"],
                  reversed: ["Injustice", "Dishonesty", "Avoidance", "Imbalance"],
                  uprightMeaning: "Truth and consequence come into balance. Decisions made with clarity bring fair outcomes.",
                  reversedMeaning: "Unfairness or avoided accountability clouds the scales. Face the truth honestly.",
                  element: "Air", symbol: "scalemass.fill"),
        TarotCard(id: 12, name: "The Hanged Man", arcana: .major, suit: nil, number: 12,
                  upright: ["Surrender", "New perspective", "Pause", "Letting go"],
                  reversed: ["Stalling", "Resistance", "Indecision", "Martyrdom"],
                  uprightMeaning: "A willing pause that reveals a new angle. Surrender control to see clearly.",
                  reversedMeaning: "Needless delay or clinging that traps you. Release the struggle and move.",
                  element: "Water", symbol: "figure.fall"),
        TarotCard(id: 13, name: "Death", arcana: .major, suit: nil, number: 13,
                  upright: ["Endings", "Transformation", "Transition", "Release"],
                  reversed: ["Resistance to change", "Stagnation", "Holding on", "Decay"],
                  uprightMeaning: "An ending that clears the way for renewal. Let what is finished fall away.",
                  reversedMeaning: "Resisting a needed ending keeps you stuck. Allow the transformation to complete.",
                  element: "Water", symbol: "hourglass"),
        TarotCard(id: 14, name: "Temperance", arcana: .major, suit: nil, number: 14,
                  upright: ["Balance", "Moderation", "Patience", "Blending"],
                  reversed: ["Excess", "Imbalance", "Impatience", "Discord"],
                  uprightMeaning: "Harmony through patient blending of opposites. The middle path heals and steadies.",
                  reversedMeaning: "Excess or impatience throws you off-center. Restore moderation and flow.",
                  element: "Fire", symbol: "drop.triangle.fill"),
        TarotCard(id: 15, name: "The Devil", arcana: .major, suit: nil, number: 15,
                  upright: ["Attachment", "Temptation", "Bondage", "Materialism"],
                  reversed: ["Release", "Reclaiming power", "Breaking free", "Awareness"],
                  uprightMeaning: "Chains of habit, fear, or craving bind you — though the locks are looser than they seem.",
                  reversedMeaning: "You begin to see the chains and loosen them. Reclaim your freedom and power.",
                  element: "Earth", symbol: "flame"),
        TarotCard(id: 16, name: "The Tower", arcana: .major, suit: nil, number: 16,
                  upright: ["Upheaval", "Sudden change", "Revelation", "Awakening"],
                  reversed: ["Averted disaster", "Fear of change", "Delaying the inevitable", "Slow collapse"],
                  uprightMeaning: "A sudden shake-up topples false foundations. Painful, but it clears the ground for truth.",
                  reversedMeaning: "You sense the crack and resist the fall. Disruption delayed is still disruption.",
                  element: "Fire", symbol: "bolt.fill"),
        TarotCard(id: 17, name: "The Star", arcana: .major, suit: nil, number: 17,
                  upright: ["Hope", "Renewal", "Inspiration", "Serenity"],
                  reversed: ["Despair", "Disconnection", "Lost faith", "Discouragement"],
                  uprightMeaning: "After the storm, gentle hope and healing return. Trust that you are guided.",
                  reversedMeaning: "Faith feels distant and inspiration dims. Reconnect with what renews you.",
                  element: "Air", symbol: "sparkles"),
        TarotCard(id: 18, name: "The Moon", arcana: .major, suit: nil, number: 18,
                  upright: ["Illusion", "Intuition", "Dreams", "The unconscious"],
                  reversed: ["Clarity", "Confusion lifting", "Truth revealed", "Fear released"],
                  uprightMeaning: "The path is lit only by moonlight — trust intuition through uncertainty and illusion.",
                  reversedMeaning: "Fog begins to clear and hidden truths surface. Confusion gives way to clarity.",
                  element: "Water", symbol: "moon.fill"),
        TarotCard(id: 19, name: "The Sun", arcana: .major, suit: nil, number: 19,
                  upright: ["Joy", "Success", "Vitality", "Positivity"],
                  reversed: ["Temporary clouds", "Blocked joy", "Overconfidence", "Delay"],
                  uprightMeaning: "Warmth, clarity, and well-earned joy. Everything is illuminated and alive.",
                  reversedMeaning: "Joy is briefly clouded or success delayed. The light is still there beneath.",
                  element: "Fire", symbol: "sun.max.fill"),
        TarotCard(id: 20, name: "Judgement", arcana: .major, suit: nil, number: 20,
                  upright: ["Awakening", "Reckoning", "Renewal", "Calling"],
                  reversed: ["Self-doubt", "Avoidance", "Harsh judgement", "Stagnation"],
                  uprightMeaning: "A clear call to rise, reflect, and step into a renewed self. Answer it.",
                  reversedMeaning: "Self-criticism or avoidance keeps you from the call. Forgive and move forward.",
                  element: "Fire", symbol: "trumpet.fill"),
        TarotCard(id: 21, name: "The World", arcana: .major, suit: nil, number: 21,
                  upright: ["Completion", "Fulfillment", "Wholeness", "Achievement"],
                  reversed: ["Incompletion", "Loose ends", "Delay", "Seeking closure"],
                  uprightMeaning: "A cycle completes in fullness and integration. You have arrived — celebrate the whole journey.",
                  reversedMeaning: "Something remains unfinished or unintegrated. Tie the loose ends to find closure.",
                  element: "Earth", symbol: "globe")
    ]

    // MARK: - Minor Arcana builder
    /// Builds the 14 cards (Ace…Ten, Page, Knight, Queen, King) for a suit,
    /// with ids starting at `base`.
    private static func suitCards(_ suit: Suit, base: Int) -> [TarotCard] {
        let data = minorData[suit] ?? []
        return data.enumerated().map { idx, d in
            TarotCard(id: base + idx, name: d.name, arcana: .minor, suit: suit, number: idx + 1,
                      upright: d.up, reversed: d.rev,
                      uprightMeaning: d.upM, reversedMeaning: d.revM,
                      element: suit.element, symbol: idx < 10 ? suit.symbol : courtSymbol(idx))
        }
    }

    private static func courtSymbol(_ idx: Int) -> String {
        switch idx {
        case 10: return "person.fill"        // Page
        case 11: return "figure.equestrian.sports" // Knight
        case 12: return "crown.fill"         // Queen
        default: return "crown.fill"         // King
        }
    }

    private struct MinorCard {
        let name: String
        let up: [String]; let rev: [String]
        let upM: String; let revM: String
    }

    private static let minorData: [Suit: [MinorCard]] = [
        .wands: [
            MinorCard(name: "Ace of Wands", up: ["Inspiration", "New energy", "Potential"], rev: ["Delays", "Lack of direction", "Hesitation"],
                      upM: "A spark of creative fire and fresh enthusiasm. Seize the new opportunity igniting before you.",
                      revM: "The spark sputters or stalls. Reconnect with what truly excites you before acting."),
            MinorCard(name: "Two of Wands", up: ["Planning", "Foresight", "Decisions"], rev: ["Fear of change", "Playing safe", "Bad planning"],
                      upM: "Standing at the threshold of a bigger world, weighing where to aim your ambition.",
                      revM: "Fear of the unknown keeps your plans small. Dare to look past the familiar horizon."),
            MinorCard(name: "Three of Wands", up: ["Expansion", "Progress", "Foresight"], rev: ["Delays", "Obstacles", "Limited vision"],
                      upM: "Your efforts set sail and progress comes into view. Trade and growth reward your foresight.",
                      revM: "Plans meet delays or your vision is too narrow. Widen your view and stay patient."),
            MinorCard(name: "Four of Wands", up: ["Celebration", "Harmony", "Homecoming"], rev: ["Tension at home", "Cancelled plans", "Instability"],
                      upM: "A joyful milestone — community, stability, and a happy threshold crossed together.",
                      revM: "Friction at home or a celebration delayed. Tend to the foundations before you feast."),
            MinorCard(name: "Five of Wands", up: ["Conflict", "Competition", "Rivalry"], rev: ["Avoiding conflict", "Resolution", "Truce"],
                      upM: "Spirited competition and clashing energies. Friction can sharpen you if channeled well.",
                      revM: "Tensions ease or are sidestepped. Find common ground and end the squabble."),
            MinorCard(name: "Six of Wands", up: ["Victory", "Recognition", "Confidence"], rev: ["Egotism", "Fall from grace", "Lack of recognition"],
                      upM: "Public success and well-earned acclaim. Ride the wave of recognition with grace.",
                      revM: "Praise wavers or pride overreaches. Stay humble and keep your footing."),
            MinorCard(name: "Seven of Wands", up: ["Perseverance", "Defense", "Standing firm"], rev: ["Overwhelm", "Giving up", "Yielding"],
                      upM: "Hold your ground against challengers. Your position is worth defending — stand firm.",
                      revM: "The defense feels exhausting and you're tempted to fold. Pick the battles that matter."),
            MinorCard(name: "Eight of Wands", up: ["Speed", "Momentum", "Swift action"], rev: ["Delays", "Frustration", "Slowing down"],
                      upM: "Things move fast — messages, travel, and momentum all arrive at once. Act swiftly.",
                      revM: "Progress stalls and frustration builds. Patience while the energy realigns."),
            MinorCard(name: "Nine of Wands", up: ["Resilience", "Persistence", "Last stand"], rev: ["Exhaustion", "Defensiveness", "Burnout"],
                      upM: "Battered but unbowed, you summon the resilience for one more push. Nearly there.",
                      revM: "Depleted reserves and a guard held too high. Rest before the final stretch."),
            MinorCard(name: "Ten of Wands", up: ["Burden", "Responsibility", "Hard work"], rev: ["Release", "Delegation", "Letting go"],
                      upM: "Carrying a heavy load to the finish. Success has its weight — almost home.",
                      revM: "Time to set down what isn't yours to carry. Delegate and lighten the burden."),
            MinorCard(name: "Page of Wands", up: ["Curiosity", "Exploration", "Free spirit"], rev: ["Aimlessness", "Hesitation", "Restlessness"],
                      upM: "An eager messenger of inspiration. Follow your curiosity wherever it sparks.",
                      revM: "Scattered enthusiasm without direction. Channel the restlessness into a real start."),
            MinorCard(name: "Knight of Wands", up: ["Energy", "Passion", "Adventure"], rev: ["Impulsiveness", "Recklessness", "Haste"],
                      upM: "Bold, charismatic, and ready to charge after a passion. Adventure calls.",
                      revM: "Passion turns impulsive and burns out fast. Aim before you gallop."),
            MinorCard(name: "Queen of Wands", up: ["Confidence", "Warmth", "Determination"], rev: ["Insecurity", "Jealousy", "Demanding"],
                      upM: "Radiant, self-assured, and magnetic. Lead with warmth and unshakable confidence.",
                      revM: "Confidence wavers into insecurity or control. Reconnect with your inner fire."),
            MinorCard(name: "King of Wands", up: ["Vision", "Leadership", "Boldness"], rev: ["Impulsiveness", "Domineering", "Overbearing"],
                      upM: "A visionary leader who inspires action. Set the bold direction and others will follow.",
                      revM: "Vision tips into impatience or tyranny. Lead with steadiness, not force.")
        ],
        .cups: [
            MinorCard(name: "Ace of Cups", up: ["New love", "Emotion", "Compassion"], rev: ["Blocked emotion", "Emptiness", "Withdrawal"],
                      upM: "An overflowing cup of love, intuition, and emotional renewal. Open your heart.",
                      revM: "Feelings are blocked or held back. Let the cup fill again by reconnecting with yourself."),
            MinorCard(name: "Two of Cups", up: ["Partnership", "Attraction", "Connection"], rev: ["Imbalance", "Breakup", "Disharmony"],
                      upM: "A meeting of hearts and mutual respect. A bond of equals deepens.",
                      revM: "A connection falls out of balance. Tend to the give-and-take or part with grace."),
            MinorCard(name: "Three of Cups", up: ["Friendship", "Celebration", "Community"], rev: ["Overindulgence", "Gossip", "Isolation"],
                      upM: "Joyful gathering with friends and shared celebration. Toast to your circle.",
                      revM: "Festivity tips into excess or your circle frays. Seek genuine connection."),
            MinorCard(name: "Four of Cups", up: ["Apathy", "Contemplation", "Reevaluation"], rev: ["Awareness", "Acceptance", "New outlook"],
                      upM: "Discontent and inward gazing — you may be overlooking a gift already offered.",
                      revM: "You lift your eyes and notice fresh possibility. Gratitude returns."),
            MinorCard(name: "Five of Cups", up: ["Loss", "Grief", "Regret"], rev: ["Acceptance", "Moving on", "Forgiveness"],
                      upM: "Mourning what spilled while two cups still stand. Grief is valid — don't forget what remains.",
                      revM: "You turn from regret toward what's left and what's ahead. Healing begins."),
            MinorCard(name: "Six of Cups", up: ["Nostalgia", "Memories", "Innocence"], rev: ["Stuck in the past", "Naivety", "Moving forward"],
                      upM: "Sweet memories and childlike kindness. Reconnect with simple, generous joys.",
                      revM: "Clinging to the past holds you back. Honor it, then step into the present."),
            MinorCard(name: "Seven of Cups", up: ["Choices", "Imagination", "Possibilities"], rev: ["Clarity", "Decision", "Reality check"],
                      upM: "A dazzling array of options and fantasies. Dream, but discern what's real.",
                      revM: "The fog of illusion clears and you choose with clarity. Focus on one true path."),
            MinorCard(name: "Eight of Cups", up: ["Walking away", "Seeking", "Transition"], rev: ["Avoidance", "Fear of change", "Staying stuck"],
                      upM: "Leaving behind what no longer fulfills you to seek something deeper. Brave departure.",
                      revM: "Torn between staying and going. Honesty about your needs will set the direction."),
            MinorCard(name: "Nine of Cups", up: ["Contentment", "Satisfaction", "Gratitude"], rev: ["Dissatisfaction", "Greed", "Unfulfilled"],
                      upM: "The wish card — emotional satisfaction and well-earned contentment. Savor it.",
                      revM: "Pleasure feels hollow or never enough. Seek meaning beneath the wish."),
            MinorCard(name: "Ten of Cups", up: ["Harmony", "Joy", "Belonging"], rev: ["Broken home", "Disconnection", "Misaligned values"],
                      upM: "Lasting emotional fulfillment and a loving, harmonious home. The dream made real.",
                      revM: "A gap between the ideal and reality of your bonds. Mend what matters."),
            MinorCard(name: "Page of Cups", up: ["Sensitivity", "Intuition", "Creativity"], rev: ["Emotional immaturity", "Insecurity", "Escapism"],
                      upM: "A tender, imaginative messenger. Welcome surprising feelings and creative whispers.",
                      revM: "Feelings overwhelm or you retreat into fantasy. Ground your sensitivity."),
            MinorCard(name: "Knight of Cups", up: ["Romance", "Charm", "Idealism"], rev: ["Moodiness", "Disappointment", "Unrealistic"],
                      upM: "A romantic on a heartfelt quest, following beauty and feeling. Follow the offer of the heart.",
                      revM: "Idealism curdles into moodiness or empty promises. Match feeling with follow-through."),
            MinorCard(name: "Queen of Cups", up: ["Compassion", "Empathy", "Calm"], rev: ["Overwhelm", "Insecurity", "Dependence"],
                      upM: "Deeply intuitive and caring, holding space for others with serene grace.",
                      revM: "Emotions flood or boundaries blur. Refill your own cup first."),
            MinorCard(name: "King of Cups", up: ["Emotional balance", "Diplomacy", "Compassion"], rev: ["Volatility", "Manipulation", "Coldness"],
                      upM: "Master of feeling and calm — leading with empathy and steady emotional wisdom.",
                      revM: "Emotions ruled by turbulence or shut away. Reclaim your balanced center.")
        ],
        .swords: [
            MinorCard(name: "Ace of Swords", up: ["Clarity", "Truth", "Breakthrough"], rev: ["Confusion", "Misinformation", "Clouded judgement"],
                      upM: "A blade of clear insight cuts through fog. Truth and a decisive breakthrough arrive.",
                      revM: "Mental fog or half-truths cloud the way. Seek the clarity beneath the noise."),
            MinorCard(name: "Two of Swords", up: ["Stalemate", "Difficult choice", "Avoidance"], rev: ["Indecision", "Confusion", "Information revealed"],
                      upM: "Blindfolded at a crossroads, balancing two options. A choice can't be avoided forever.",
                      revM: "The blindfold lifts and new information breaks the deadlock. Decide."),
            MinorCard(name: "Three of Swords", up: ["Heartbreak", "Sorrow", "Grief"], rev: ["Healing", "Forgiveness", "Recovery"],
                      upM: "Painful truth pierces the heart. Grief is the honest cost of having cared.",
                      revM: "The wound begins to close. Forgiveness and release let the heart mend."),
            MinorCard(name: "Four of Swords", up: ["Rest", "Recovery", "Contemplation"], rev: ["Restlessness", "Burnout", "Stagnation"],
                      upM: "A needed pause to heal and gather strength. Retreat is wise, not weak.",
                      revM: "Avoiding needed rest leads to burnout — or rest overstayed. Find the balance to re-enter."),
            MinorCard(name: "Five of Swords", up: ["Conflict", "Defeat", "Win at all costs"], rev: ["Reconciliation", "Making amends", "Moving on"],
                      upM: "A hollow victory or a stinging loss. Ask whether winning was worth the cost.",
                      revM: "A chance to make amends and lay down the conflict. Choose peace over pride."),
            MinorCard(name: "Six of Swords", up: ["Transition", "Moving on", "Recovery"], rev: ["Resistance", "Stuck", "Unfinished business"],
                      upM: "Leaving turbulent waters for calmer shores. A gentle, necessary passage forward.",
                      revM: "Resistance keeps you tethered to rough waters. Release what holds you back."),
            MinorCard(name: "Seven of Swords", up: ["Strategy", "Stealth", "Deception"], rev: ["Conscience", "Coming clean", "Exposure"],
                      upM: "Cunning and quiet maneuvering. Be strategic — but watch the ethics of your tactics.",
                      revM: "Hidden moves come to light or conscience calls. Honesty restores trust."),
            MinorCard(name: "Eight of Swords", up: ["Restriction", "Self-limiting", "Trapped"], rev: ["Self-acceptance", "New perspective", "Freedom"],
                      upM: "Bound and blindfolded — yet the trap is largely of the mind. The way out exists.",
                      revM: "You loosen the mental bindings and step free. Clarity reveals the open path."),
            MinorCard(name: "Nine of Swords", up: ["Anxiety", "Worry", "Fear"], rev: ["Hope", "Relief", "Facing fears"],
                      upM: "Sleepless dread and spiraling worry. The night feels darkest in the mind.",
                      revM: "Fears are faced and lose their grip. Dawn and relief return."),
            MinorCard(name: "Ten of Swords", up: ["Painful ending", "Rock bottom", "Betrayal"], rev: ["Recovery", "Regeneration", "Survival"],
                      upM: "A definitive, painful ending. The worst is over — there is nowhere to go but up.",
                      revM: "Rising from the lowest point. Survival and slow recovery begin."),
            MinorCard(name: "Page of Swords", up: ["Curiosity", "New ideas", "Vigilance"], rev: ["Scattered thoughts", "Deception", "All talk"],
                      upM: "A sharp, inquisitive messenger of ideas. Ask questions and stay alert.",
                      revM: "Restless thoughts, gossip, or all talk and no action. Focus the mind."),
            MinorCard(name: "Knight of Swords", up: ["Ambition", "Drive", "Fast action"], rev: ["Impulsiveness", "Recklessness", "Burnout"],
                      upM: "Charging ahead with sharp focus and fierce ambition. Bold, direct action.",
                      revM: "Haste outruns thought, leaving collateral behind. Slow down and aim."),
            MinorCard(name: "Queen of Swords", up: ["Clarity", "Independence", "Honesty"], rev: ["Coldness", "Bitterness", "Harsh judgement"],
                      upM: "Clear-eyed and independent, cutting to the truth with fair, unsentimental wisdom.",
                      revM: "Clarity hardens into coldness or bitterness. Temper honesty with warmth."),
            MinorCard(name: "King of Swords", up: ["Intellect", "Authority", "Truth"], rev: ["Manipulation", "Tyranny", "Misuse of power"],
                      upM: "Master of reason and principle, ruling with clear judgement and fair authority.",
                      revM: "Intellect turns manipulative or cold. Lead with integrity, not control.")
        ],
        .pentacles: [
            MinorCard(name: "Ace of Pentacles", up: ["Opportunity", "Prosperity", "New venture"], rev: ["Missed chance", "Scarcity", "Bad investment"],
                      upM: "A seed of material opportunity and lasting prosperity. Plant it with intention.",
                      revM: "An opportunity slips or feels precarious. Steady your resources before you sow."),
            MinorCard(name: "Two of Pentacles", up: ["Balance", "Adaptability", "Juggling"], rev: ["Overwhelm", "Disorganization", "Imbalance"],
                      upM: "Juggling priorities with nimble grace. Flexibility keeps the plates spinning.",
                      revM: "Too many demands tip you off-balance. Simplify and reprioritize."),
            MinorCard(name: "Three of Pentacles", up: ["Teamwork", "Collaboration", "Skill"], rev: ["Discord", "Lack of teamwork", "Mediocrity"],
                      upM: "Skilled collaboration builds something to be proud of. Many hands, shared craft.",
                      revM: "Misaligned teamwork or unrecognized skill stalls the work. Realign the effort."),
            MinorCard(name: "Four of Pentacles", up: ["Security", "Saving", "Holding on"], rev: ["Greed", "Letting go", "Generosity"],
                      upM: "Holding tight to stability and resources. Security is good — clutching too hard is not.",
                      revM: "You loosen your grip — for better through generosity, or worse through loss. Find healthy flow."),
            MinorCard(name: "Five of Pentacles", up: ["Hardship", "Insecurity", "Lack"], rev: ["Recovery", "Support found", "Turning point"],
                      upM: "A season of want or feeling left out in the cold. Help may be nearer than it seems.",
                      revM: "Recovery begins and support appears. The hard season turns toward relief."),
            MinorCard(name: "Six of Pentacles", up: ["Generosity", "Charity", "Sharing"], rev: ["Strings attached", "Inequality", "One-sided giving"],
                      upM: "A fair flow of giving and receiving. Generosity balances the scales.",
                      revM: "Giving with strings or an uneven exchange. Restore true reciprocity."),
            MinorCard(name: "Seven of Pentacles", up: ["Patience", "Long-term view", "Assessment"], rev: ["Impatience", "Lack of reward", "Poor planning"],
                      upM: "Pausing to assess a slow-growing investment. Patience lets the harvest ripen.",
                      revM: "Frustration at slow returns or effort misplaced. Reassess where you plant."),
            MinorCard(name: "Eight of Pentacles", up: ["Mastery", "Diligence", "Craftsmanship"], rev: ["Perfectionism", "Lack of focus", "Uninspired"],
                      upM: "Devoted, skillful work and steady improvement. Mastery is built one detail at a time.",
                      revM: "Perfectionism or boredom dulls the craft. Reconnect with purpose in the work."),
            MinorCard(name: "Nine of Pentacles", up: ["Abundance", "Self-sufficiency", "Luxury"], rev: ["Overinvestment in work", "Hustling", "Financial dependence"],
                      upM: "Refined independence and the comfort of self-made abundance. Enjoy the fruits.",
                      revM: "Comfort built on overwork, or reliance on others. Find true self-sufficiency."),
            MinorCard(name: "Ten of Pentacles", up: ["Legacy", "Wealth", "Family"], rev: ["Financial instability", "Loss", "Broken traditions"],
                      upM: "Lasting wealth, family stability, and a legacy that endures. The long game pays off.",
                      revM: "Instability or strained legacy threatens the foundation. Tend to what lasts."),
            MinorCard(name: "Page of Pentacles", up: ["Ambition", "Study", "New opportunity"], rev: ["Procrastination", "Lack of progress", "Distraction"],
                      upM: "An earnest student-messenger of opportunity. Apply yourself to a tangible new goal.",
                      revM: "Procrastination or distraction stalls the start. Take one concrete step."),
            MinorCard(name: "Knight of Pentacles", up: ["Diligence", "Routine", "Reliability"], rev: ["Stagnation", "Boredom", "Laziness"],
                      upM: "Methodical, dependable, and patient. Steady effort gets the job done right.",
                      revM: "Routine hardens into rut or inertia. Add a spark to renew momentum."),
            MinorCard(name: "Queen of Pentacles", up: ["Nurturing", "Practical", "Abundance"], rev: ["Self-neglect", "Smothering", "Work-life imbalance"],
                      upM: "Grounded and generous, nurturing both home and resources with warm practicality.",
                      revM: "Caring for all but yourself, or a tilted work-life balance. Replenish your own well."),
            MinorCard(name: "King of Pentacles", up: ["Abundance", "Security", "Leadership"], rev: ["Greed", "Materialism", "Stubbornness"],
                      upM: "A prosperous, grounded leader who builds enduring security. Steward your resources well.",
                      revM: "Success tips into greed or rigidity. Lead with generosity and adaptability.")
        ]
    ]
}
