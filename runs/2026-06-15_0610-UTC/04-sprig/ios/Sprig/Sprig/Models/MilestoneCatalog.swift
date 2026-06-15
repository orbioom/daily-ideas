import Foundation

/// Developmental domain for a milestone (CDC "Learn the Signs" categories).
enum MilestoneCategory: String, CaseIterable, Identifiable, Codable {
    case social
    case language
    case cognitive
    case motor
    var id: String { rawValue }

    var title: String {
        switch self {
        case .social:    return "Social / Emotional"
        case .language:  return "Language / Communication"
        case .cognitive: return "Cognitive"
        case .motor:     return "Movement / Physical"
        }
    }

    var symbol: String {
        switch self {
        case .social:    return "heart.fill"
        case .language:  return "bubble.left.and.bubble.right.fill"
        case .cognitive: return "brain.head.profile"
        case .motor:     return "figure.walk"
        }
    }
}

/// One developmental milestone from the curated catalog.
struct Milestone: Identifiable {
    let key: String
    let category: MilestoneCategory
    let title: String
    /// The age (months) by which most children show this skill (CDC "by X months" guidance).
    let typicalAgeMonths: Int

    var id: String { key }

    /// The age band this milestone is grouped under.
    var band: AgeBand { AgeBand.band(forMonths: typicalAgeMonths) }
}

/// Age bands used to group milestones and vaccines on screen.
enum AgeBand: Int, CaseIterable, Identifiable {
    case m2 = 2
    case m4 = 4
    case m6 = 6
    case m9 = 9
    case m12 = 12
    case m18 = 18
    case m24 = 24
    case m36 = 36
    case m48 = 48
    case m60 = 60

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .m2:  return "By 2 months"
        case .m4:  return "By 4 months"
        case .m6:  return "By 6 months"
        case .m9:  return "By 9 months"
        case .m12: return "By 12 months"
        case .m18: return "By 18 months"
        case .m24: return "By 2 years"
        case .m36: return "By 3 years"
        case .m48: return "By 4 years"
        case .m60: return "By 5 years"
        }
    }

    static func band(forMonths months: Int) -> AgeBand {
        for band in AgeBand.allCases where months <= band.rawValue {
            return band
        }
        return .m60
    }
}

/// The curated CDC milestone catalog. Keys are stable; titles paraphrase CDC guidance.
enum MilestoneCatalog {
    static let all: [Milestone] = [
        // By 2 months
        Milestone(key: "m2.social.calm", category: .social, title: "Calms down when spoken to or picked up", typicalAgeMonths: 2),
        Milestone(key: "m2.social.smile", category: .social, title: "Smiles when you talk to or smile at them", typicalAgeMonths: 2),
        Milestone(key: "m2.lang.coo", category: .language, title: "Makes sounds other than crying (cooing)", typicalAgeMonths: 2),
        Milestone(key: "m2.cog.watch", category: .cognitive, title: "Watches you as you move", typicalAgeMonths: 2),
        Milestone(key: "m2.motor.head", category: .motor, title: "Holds head up during tummy time", typicalAgeMonths: 2),

        // By 4 months
        Milestone(key: "m4.social.laugh", category: .social, title: "Smiles to get your attention", typicalAgeMonths: 4),
        Milestone(key: "m4.lang.babble", category: .language, title: "Makes cooing sounds back and forth", typicalAgeMonths: 4),
        Milestone(key: "m4.cog.reach", category: .cognitive, title: "Reaches for and grabs a toy", typicalAgeMonths: 4),
        Milestone(key: "m4.motor.steady", category: .motor, title: "Holds head steady without support", typicalAgeMonths: 4),
        Milestone(key: "m4.motor.push", category: .motor, title: "Pushes up on elbows during tummy time", typicalAgeMonths: 4),

        // By 6 months
        Milestone(key: "m6.social.mirror", category: .social, title: "Recognizes familiar faces", typicalAgeMonths: 6),
        Milestone(key: "m6.lang.sounds", category: .language, title: "Takes turns making sounds with you", typicalAgeMonths: 6),
        Milestone(key: "m6.cog.mouth", category: .cognitive, title: "Puts things in their mouth to explore", typicalAgeMonths: 6),
        Milestone(key: "m6.motor.roll", category: .motor, title: "Rolls from tummy to back", typicalAgeMonths: 6),
        Milestone(key: "m6.motor.sit", category: .motor, title: "Sits with support / leaning on hands", typicalAgeMonths: 6),

        // By 9 months
        Milestone(key: "m9.social.shy", category: .social, title: "Shy or nervous with strangers", typicalAgeMonths: 9),
        Milestone(key: "m9.lang.babble", category: .language, title: "Makes a lot of sounds like mamama, bababa", typicalAgeMonths: 9),
        Milestone(key: "m9.cog.peekaboo", category: .cognitive, title: "Looks for objects when dropped (peek-a-boo)", typicalAgeMonths: 9),
        Milestone(key: "m9.motor.sitalone", category: .motor, title: "Sits without support", typicalAgeMonths: 9),
        Milestone(key: "m9.motor.transfer", category: .motor, title: "Moves things from one hand to the other", typicalAgeMonths: 9),

        // By 12 months
        Milestone(key: "m12.social.wave", category: .social, title: "Plays games like pat-a-cake", typicalAgeMonths: 12),
        Milestone(key: "m12.lang.mama", category: .language, title: "Says mama or dada with meaning", typicalAgeMonths: 12),
        Milestone(key: "m12.cog.bang", category: .cognitive, title: "Bangs two things together", typicalAgeMonths: 12),
        Milestone(key: "m12.motor.pull", category: .motor, title: "Pulls up to stand", typicalAgeMonths: 12),
        Milestone(key: "m12.motor.cruise", category: .motor, title: "Walks holding on to furniture (cruising)", typicalAgeMonths: 12),

        // By 18 months
        Milestone(key: "m18.social.point", category: .social, title: "Points to show you something interesting", typicalAgeMonths: 18),
        Milestone(key: "m18.lang.words", category: .language, title: "Tries to say three or more words besides mama/dada", typicalAgeMonths: 18),
        Milestone(key: "m18.cog.spoon", category: .cognitive, title: "Tries to use a spoon", typicalAgeMonths: 18),
        Milestone(key: "m18.motor.walk", category: .motor, title: "Walks without holding on", typicalAgeMonths: 18),
        Milestone(key: "m18.motor.scribble", category: .motor, title: "Scribbles with a crayon", typicalAgeMonths: 18),

        // By 24 months
        Milestone(key: "m24.social.copy", category: .social, title: "Copies others, especially adults", typicalAgeMonths: 24),
        Milestone(key: "m24.lang.point", category: .language, title: "Points to things in a book when asked", typicalAgeMonths: 24),
        Milestone(key: "m24.lang.two", category: .language, title: "Says two-word phrases (more milk)", typicalAgeMonths: 24),
        Milestone(key: "m24.cog.sort", category: .cognitive, title: "Plays with more than one toy at a time", typicalAgeMonths: 24),
        Milestone(key: "m24.motor.run", category: .motor, title: "Runs and kicks a ball", typicalAgeMonths: 24),

        // By 36 months (3 yr)
        Milestone(key: "m36.social.calm", category: .social, title: "Calms within 10 minutes after you leave", typicalAgeMonths: 36),
        Milestone(key: "m36.lang.convo", category: .language, title: "Talks in 2–3 sentence conversations", typicalAgeMonths: 36),
        Milestone(key: "m36.cog.puzzle", category: .cognitive, title: "Works toys with buttons and moving parts", typicalAgeMonths: 36),
        Milestone(key: "m36.motor.stairs", category: .motor, title: "Climbs stairs one foot per step", typicalAgeMonths: 36),

        // By 48 months (4 yr)
        Milestone(key: "m48.social.pretend", category: .social, title: "Pretends to be something else during play", typicalAgeMonths: 48),
        Milestone(key: "m48.lang.story", category: .language, title: "Says sentences with four or more words", typicalAgeMonths: 48),
        Milestone(key: "m48.cog.count", category: .cognitive, title: "Names a few colors of items", typicalAgeMonths: 48),
        Milestone(key: "m48.motor.hop", category: .motor, title: "Catches a large ball most of the time", typicalAgeMonths: 48),

        // By 60 months (5 yr)
        Milestone(key: "m60.social.rules", category: .social, title: "Follows rules or takes turns in games", typicalAgeMonths: 60),
        Milestone(key: "m60.lang.tell", category: .language, title: "Tells a simple story with two events", typicalAgeMonths: 60),
        Milestone(key: "m60.cog.count", category: .cognitive, title: "Counts to ten", typicalAgeMonths: 60),
        Milestone(key: "m60.motor.hop", category: .motor, title: "Hops on one foot", typicalAgeMonths: 60)
    ]

    static let byKey: [String: Milestone] = Dictionary(uniqueKeysWithValues: all.map { ($0.key, $0) })

    /// Milestones grouped by age band, in band order.
    static var byBand: [(band: AgeBand, items: [Milestone])] {
        AgeBand.allCases.compactMap { band in
            let items = all.filter { $0.band == band }
            return items.isEmpty ? nil : (band, items)
        }
    }
}

/// On-track status of a milestone given a child's current age.
enum MilestoneStatus {
    case achieved
    case onTrack       // not yet, but child is younger than the typical window end
    case keepAnEye     // overdue: child is past the typical age and not yet achieved

    var title: String {
        switch self {
        case .achieved:   return "Achieved"
        case .onTrack:    return "On track"
        case .keepAnEye:  return "Keep an eye"
        }
    }

    /// Compute status from child age, the milestone's typical age, and whether achieved.
    static func status(childAgeMonths: Int, typicalAgeMonths: Int, achieved: Bool) -> MilestoneStatus {
        if achieved { return .achieved }
        // Grace window: a milestone isn't "behind" until ~2 months past the typical age.
        let grace = 2
        return childAgeMonths > typicalAgeMonths + grace ? .keepAnEye : .onTrack
    }
}
