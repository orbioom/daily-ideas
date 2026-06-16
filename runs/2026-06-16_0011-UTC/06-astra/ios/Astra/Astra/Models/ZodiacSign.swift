import SwiftUI

enum Element: String {
    case fire = "Fire"
    case earth = "Earth"
    case air = "Air"
    case water = "Water"

    var color: Color {
        switch self {
        case .fire: return Color.dyn(0xD4602F, 0xF09060)
        case .earth: return Color.dyn(0x5A7A3A, 0x9BC06A)
        case .air: return Color.dyn(0x4A7BB0, 0x8FC0EE)
        case .water: return Color.dyn(0x4A5FB0, 0x8FA0EE)
        }
    }
}

enum Modality: String {
    case cardinal = "Cardinal"
    case fixed = "Fixed"
    case mutable = "Mutable"
}

/// The twelve zodiac signs in tropical order, plus a real interpretation library.
enum ZodiacSign: Int, CaseIterable, Identifiable {
    case aries = 0, taurus, gemini, cancer, leo, virgo
    case libra, scorpio, sagittarius, capricorn, aquarius, pisces

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .aries: return "Aries"
        case .taurus: return "Taurus"
        case .gemini: return "Gemini"
        case .cancer: return "Cancer"
        case .leo: return "Leo"
        case .virgo: return "Virgo"
        case .libra: return "Libra"
        case .scorpio: return "Scorpio"
        case .sagittarius: return "Sagittarius"
        case .capricorn: return "Capricorn"
        case .aquarius: return "Aquarius"
        case .pisces: return "Pisces"
        }
    }

    /// Unicode astrological glyph.
    var glyph: String {
        switch self {
        case .aries: return "\u{2648}"
        case .taurus: return "\u{2649}"
        case .gemini: return "\u{264A}"
        case .cancer: return "\u{264B}"
        case .leo: return "\u{264C}"
        case .virgo: return "\u{264D}"
        case .libra: return "\u{264E}"
        case .scorpio: return "\u{264F}"
        case .sagittarius: return "\u{2650}"
        case .capricorn: return "\u{2651}"
        case .aquarius: return "\u{2652}"
        case .pisces: return "\u{2653}"
        }
    }

    var element: Element {
        switch self {
        case .aries, .leo, .sagittarius: return .fire
        case .taurus, .virgo, .capricorn: return .earth
        case .gemini, .libra, .aquarius: return .air
        case .cancer, .scorpio, .pisces: return .water
        }
    }

    var modality: Modality {
        switch self {
        case .aries, .cancer, .libra, .capricorn: return .cardinal
        case .taurus, .leo, .scorpio, .aquarius: return .fixed
        case .gemini, .virgo, .sagittarius, .pisces: return .mutable
        }
    }

    var rulingPlanet: Planet {
        switch self {
        case .aries: return .mars
        case .taurus: return .venus
        case .gemini: return .mercury
        case .cancer: return .moon
        case .leo: return .sun
        case .virgo: return .mercury
        case .libra: return .venus
        case .scorpio: return .pluto
        case .sagittarius: return .jupiter
        case .capricorn: return .saturn
        case .aquarius: return .uranus
        case .pisces: return .neptune
        }
    }

    var dateRange: String {
        switch self {
        case .aries: return "Mar 21 – Apr 19"
        case .taurus: return "Apr 20 – May 20"
        case .gemini: return "May 21 – Jun 20"
        case .cancer: return "Jun 21 – Jul 22"
        case .leo: return "Jul 23 – Aug 22"
        case .virgo: return "Aug 23 – Sep 22"
        case .libra: return "Sep 23 – Oct 22"
        case .scorpio: return "Oct 23 – Nov 21"
        case .sagittarius: return "Nov 22 – Dec 21"
        case .capricorn: return "Dec 22 – Jan 19"
        case .aquarius: return "Jan 20 – Feb 18"
        case .pisces: return "Feb 19 – Mar 20"
        }
    }

    var keywords: [String] {
        switch self {
        case .aries: return ["bold", "direct", "pioneering"]
        case .taurus: return ["steady", "sensual", "grounded"]
        case .gemini: return ["curious", "quick", "versatile"]
        case .cancer: return ["caring", "protective", "tidal"]
        case .leo: return ["warm", "expressive", "proud"]
        case .virgo: return ["precise", "helpful", "discerning"]
        case .libra: return ["fair", "relational", "poised"]
        case .scorpio: return ["intense", "private", "transformative"]
        case .sagittarius: return ["expansive", "honest", "restless"]
        case .capricorn: return ["disciplined", "ambitious", "patient"]
        case .aquarius: return ["inventive", "independent", "humane"]
        case .pisces: return ["intuitive", "compassionate", "porous"]
        }
    }

    /// Concise, grounded interpretation — not generic horoscope filler.
    var summary: String {
        switch self {
        case .aries:
            return "Cardinal fire. You start things — fast, frank, and first. The work is learning to finish, and to let others move at their own speed."
        case .taurus:
            return "Fixed earth. You build slowly and keep what's worth keeping. Comfort, loyalty, and the senses ground you; rigidity is the cost when you over-root."
        case .gemini:
            return "Mutable air. A mind that loves options, links, and conversation. Depth comes when you stay long enough to follow a thread to its end."
        case .cancer:
            return "Cardinal water. You lead with care and read the room before it speaks. Home and memory anchor you; the shell protects a real tenderness."
        case .leo:
            return "Fixed fire. Generous, warm, and meant to be seen. You shine brightest giving others the spotlight, not competing for it."
        case .virgo:
            return "Mutable earth. You improve things by noticing what's off. Service and craft are your love language; the trap is mistaking perfect for done."
        case .libra:
            return "Cardinal air. You weigh, relate, and seek the fair middle. Balance is the aim, but a real stance — your own — is what makes harmony stick."
        case .scorpio:
            return "Fixed water. You go all the way or not at all. Trust is earned slowly; once given, you transform with whoever earns it."
        case .sagittarius:
            return "Mutable fire. You chase the bigger picture — travel, meaning, the next horizon. Honesty is your gift; tact is the lesson."
        case .capricorn:
            return "Cardinal earth. You climb with patience and respect the long game. Mastery suits you; remember the summit is for living on, not just reaching."
        case .aquarius:
            return "Fixed air. You think in systems and side with the future. Independence is your strength; warmth, freely given, is your growth edge."
        case .pisces:
            return "Mutable water. You feel the current beneath the surface. Imagination and empathy run deep; boundaries are the skill that protects the gift."
        }
    }

    static func fromLongitude(_ lon: Double) -> ZodiacSign {
        let normalized = ((lon.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
        let index = Int(floor(normalized / 30))
        let safe = min(max(index, 0), 11)
        return ZodiacSign(rawValue: safe) ?? .aries
    }
}
