import Foundation

/// A curated meaning for a single number.
struct NumberMeaning: Identifiable, Equatable {
    let number: Int
    let title: String        // archetype, e.g. "The Seeker"
    let keywords: [String]
    let strengths: [String]
    let challenges: [String]
    let essence: String      // substantive paragraph

    var id: Int { number }

    /// A position-aware framing line, e.g. what this number means as a Life Path
    /// versus a Soul Urge. Real, distinct phrasing per position.
    func framing(for position: NumberPosition) -> String {
        switch position {
        case .lifePath:
            return "As your Life Path, \(number) is the road itself — the recurring lesson your years keep returning to."
        case .expression:
            return "As your Expression, \(number) describes your native toolkit: the talents you reach for when you build a life."
        case .soulUrge:
            return "As your Soul Urge, \(number) is the quiet wish underneath your choices — what genuinely satisfies you."
        case .personality:
            return "As your Personality, \(number) is the doorway others walk through first — your outward style and first impression."
        case .birthday:
            return "As your Birthday number, \(number) is a specific, ready-made gift you were handed at birth."
        case .maturity:
            return "As your Maturity number, \(number) is the integration your later decades move toward, blending path and talent."
        case .personalYear:
            return "As this year's theme, \(number) colours the whole twelve months — the lesson the year keeps offering."
        case .personalMonth:
            return "As this month's tone, \(number) is the shorter rhythm inside the year — where to put your attention now."
        case .personalDay:
            return "As today's number, \(number) is the day's weather: a gentle suggestion for how to spend your energy."
        }
    }
}

/// The curated interpretation library: 1–9 plus master numbers 11/22/33.
enum InterpretationLibrary {

    /// Ordered list for the Library browse screen.
    static let all: [NumberMeaning] = [one, two, three, four, five, six, seven, eight, nine, eleven, twentyTwo, thirtyThree]

    static func meaning(for number: Int) -> NumberMeaning {
        all.first(where: { $0.number == number }) ?? fallback(for: number)
    }

    /// Defensive fallback so an unexpected value never returns nil to the UI.
    private static func fallback(for number: Int) -> NumberMeaning {
        // Reduce defensively to a known root and return that meaning's text under the raw number.
        let root = number > 9 ? ((number - 1) % 9 + 1) : max(1, number)
        let base = all.first(where: { $0.number == root }) ?? one
        return NumberMeaning(
            number: number,
            title: base.title,
            keywords: base.keywords,
            strengths: base.strengths,
            challenges: base.challenges,
            essence: base.essence
        )
    }

    // MARK: Entries

    static let one = NumberMeaning(
        number: 1,
        title: "The Pioneer",
        keywords: ["Independence", "Initiative", "Leadership", "Originality"],
        strengths: ["Self-starting drive", "Courage to go first", "Clear sense of direction", "Inventiveness"],
        challenges: ["Stubbornness", "Impatience with others", "Loneliness at the front", "Difficulty asking for help"],
        essence: "One is the number of beginnings — the single upright stroke from which all other numbers descend. It carries the raw will to initiate, to stand apart, and to forge a path where none existed. People shaped by the One are happiest when they are originating rather than maintaining, leading rather than following. The work of this number is to balance fierce independence with the humility to let others walk beside you, so that pioneering does not curdle into isolation."
    )

    static let two = NumberMeaning(
        number: 2,
        title: "The Peacemaker",
        keywords: ["Harmony", "Sensitivity", "Partnership", "Diplomacy"],
        strengths: ["Deep empathy", "Talent for mediation", "Patience", "Attention to feeling and nuance"],
        challenges: ["Over-sensitivity", "Self-erasure", "Indecision", "Fear of conflict"],
        essence: "Two is the number of relationship — the moment the One discovers an Other and the whole grammar of cooperation begins. It governs balance, tact, and the quiet power of the supporting role. Those who carry the Two read rooms effortlessly and soothe tension others cannot even name. The lesson here is to honour your own needs as fully as you honour everyone else's, so that gentleness becomes a strength rather than a place to hide."
    )

    static let three = NumberMeaning(
        number: 3,
        title: "The Communicator",
        keywords: ["Expression", "Joy", "Creativity", "Imagination"],
        strengths: ["Magnetic self-expression", "Optimism", "Artistic gift", "Social warmth"],
        challenges: ["Scattered focus", "Superficiality", "Mood swings", "Avoiding hard feelings with humour"],
        essence: "Three is the child of One and Two — the creative spark born from union, delighting in colour, word, and play. It is the storyteller and the artist, turning raw feeling into something others can enjoy. People with strong Threes light up a room and find joy a renewable resource. Their growth lies in directing that abundant energy: choosing depth over dazzle, and finishing what the imagination so easily begins."
    )

    static let four = NumberMeaning(
        number: 4,
        title: "The Builder",
        keywords: ["Stability", "Discipline", "Order", "Devotion"],
        strengths: ["Reliability", "Patience for the long task", "Practical wisdom", "Loyalty"],
        challenges: ["Rigidity", "Resistance to change", "Workaholism", "Bluntness"],
        essence: "Four is the square, the foundation, the four walls and four seasons — the number that turns ideas into something you can stand on. It values structure, craft, and the honest reward of work done well. Those guided by the Four are the dependable cornerstones in any life or enterprise. Their challenge is to keep the walls from becoming a cage: to remember that systems exist to serve life, and that flexibility is its own kind of strength."
    )

    static let five = NumberMeaning(
        number: 5,
        title: "The Free Spirit",
        keywords: ["Freedom", "Change", "Adventure", "Curiosity"],
        strengths: ["Adaptability", "Charisma", "Quick mind", "Love of experience"],
        challenges: ["Restlessness", "Impulsiveness", "Difficulty committing", "Excess"],
        essence: "Five sits at the centre of the single digits, the pivot of change and the senses. It is movement, travel, appetite, and the refusal to be boxed in. People with strong Fives gather experiences the way others gather possessions, and they teach the rest of us how to be brave with the unknown. Their work is to find the freedom inside commitment — to discover that depth, not just variety, can satisfy a restless heart."
    )

    static let six = NumberMeaning(
        number: 6,
        title: "The Nurturer",
        keywords: ["Responsibility", "Love", "Service", "Beauty"],
        strengths: ["Devotion to others", "Strong sense of duty", "Aesthetic eye", "Healing presence"],
        challenges: ["Self-sacrifice", "Worry", "Tendency to control through care", "Martyrdom"],
        essence: "Six is the number of home, family, and the responsibility we take for one another. It is harmony made domestic — the warm hearth, the cared-for garden, the well-set table. Those carrying the Six are natural caretakers and counsellors, drawn to make things beautiful and people whole. The lesson is to give from fullness rather than obligation, and to let those they love carry their own weight, so service stays generous and never becomes a quiet form of control."
    )

    static let seven = NumberMeaning(
        number: 7,
        title: "The Seeker",
        keywords: ["Wisdom", "Introspection", "Analysis", "Spirituality"],
        strengths: ["Deep thinking", "Intuition", "Love of truth", "Comfort with solitude"],
        challenges: ["Aloofness", "Over-analysis", "Cynicism", "Difficulty trusting"],
        essence: "Seven is the contemplative — the number that withdraws from the marketplace to ask what any of it means. It governs study, mysticism, and the patient search for what lies beneath appearances. People shaped by the Seven need solitude the way others need company, and they often arrive at insights the busier world misses. Their growth lies in trusting both head and heart, and in letting others close enough to share the truths they uncover alone."
    )

    static let eight = NumberMeaning(
        number: 8,
        title: "The Powerhouse",
        keywords: ["Ambition", "Authority", "Abundance", "Mastery"],
        strengths: ["Executive vision", "Resilience", "Material competence", "Fair judgment"],
        challenges: ["Workaholism", "Control", "Materialism", "Difficulty with vulnerability"],
        essence: "Eight is the number of worldly power — the balanced infinity sign, where the spiritual and material meet on equal terms. It governs ambition, money, authority, and the karmic law that what we give returns to us. Those carrying the Eight are built to manage, to build wealth and institutions, and to wield influence. The lesson is to keep power in service of something larger than the self, so that mastery of the material world does not cost the inner one."
    )

    static let nine = NumberMeaning(
        number: 9,
        title: "The Humanitarian",
        keywords: ["Compassion", "Idealism", "Completion", "Wisdom"],
        strengths: ["Broad empathy", "Generosity", "Artistic depth", "Tolerance"],
        challenges: ["Difficulty letting go", "Emotional distance", "Self-righteousness", "Burnout from giving"],
        essence: "Nine is the last and largest single digit — the number of endings, integration, and love for humanity as a whole. It has travelled through all the other numbers and carries something of each, which is why it forgives so easily and sees so widely. Those guided by the Nine are old souls, drawn to causes larger than themselves. Their work is to release what is finished gracefully, and to let their vast compassion include the one person it most often forgets: themselves."
    )

    static let eleven = NumberMeaning(
        number: 11,
        title: "The Illuminator",
        keywords: ["Intuition", "Inspiration", "Vision", "Sensitivity"],
        strengths: ["Spiritual insight", "Inspirational presence", "Heightened intuition", "Idealism"],
        challenges: ["Nervous tension", "Self-doubt", "Impracticality", "Overwhelm"],
        essence: "Eleven is the first master number — the Two raised to a higher octave, a channel between the seen and unseen. It carries the sensitivity and partnership of the Two but charges them with visionary current. People who hold an Eleven often feel like antennas, picking up what others miss and inspiring them toward something higher. The challenge is grounding: learning to live with such an open nervous system, and to turn flashes of insight into work the world can use."
    )

    static let twentyTwo = NumberMeaning(
        number: 22,
        title: "The Master Builder",
        keywords: ["Vision", "Manifestation", "Mastery", "Legacy"],
        strengths: ["Turning dreams into structures", "Immense capability", "Practical idealism", "Endurance"],
        challenges: ["Crushing self-imposed pressure", "Overwhelm at the scale of the vision", "Control", "Burnout"],
        essence: "Twenty-two is the most powerful number, the Four raised to its highest expression — the architect who can build dreams into lasting form. It marries the Eleven's vision with the Four's discipline, giving it the rare ability to leave something permanent behind. Those who carry a Twenty-two feel a pull toward large-scale work that serves many. Their lesson is patience and faith: the vision is real, but it asks for steady, humble building rather than a single heroic leap."
    )

    static let thirtyThree = NumberMeaning(
        number: 33,
        title: "The Master Teacher",
        keywords: ["Compassion", "Devotion", "Healing", "Selfless service"],
        strengths: ["Unconditional love", "Profound nurturing", "Spiritual leadership", "Wisdom in service"],
        challenges: ["Self-neglect", "Carrying others' burdens", "Impossible standards", "Martyrdom"],
        essence: "Thirty-three is the rarest master number, the Six lifted to its most luminous form — love made into a calling. It blends the Eleven's vision and the Twenty-two's building power into pure, selfless service, often expressed through teaching and healing. Those who genuinely carry a Thirty-three are here to uplift others without losing themselves. The lesson, harder than it sounds, is to receive as well as give, so that the well they draw from for everyone else never runs dry."
    )
}
