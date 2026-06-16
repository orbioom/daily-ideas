import SwiftUI

/// The bodies Astra computes. Sun through Neptune are computed from Schlyter's
/// orbital elements; Pluto uses fixed modern mean elements (it moves slowly and
/// its tiny mass makes a Keplerian two-body approximation acceptable for a chart).
enum Planet: Int, CaseIterable, Identifiable {
    case sun = 0, moon, mercury, venus, mars, jupiter, saturn, uranus, neptune, pluto

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .sun: return "Sun"
        case .moon: return "Moon"
        case .mercury: return "Mercury"
        case .venus: return "Venus"
        case .mars: return "Mars"
        case .jupiter: return "Jupiter"
        case .saturn: return "Saturn"
        case .uranus: return "Uranus"
        case .neptune: return "Neptune"
        case .pluto: return "Pluto"
        }
    }

    var glyph: String {
        switch self {
        case .sun: return "\u{2609}"
        case .moon: return "\u{263D}"
        case .mercury: return "\u{263F}"
        case .venus: return "\u{2640}"
        case .mars: return "\u{2642}"
        case .jupiter: return "\u{2643}"
        case .saturn: return "\u{2644}"
        case .uranus: return "\u{2645}"
        case .neptune: return "\u{2646}"
        case .pluto: return "\u{2647}"
        }
    }

    /// The "personal" planets move quickly and shape day-to-day personality.
    var isPersonal: Bool {
        switch self {
        case .sun, .moon, .mercury, .venus, .mars: return true
        default: return false
        }
    }

    /// A luminary (Sun/Moon) gets a wider aspect orb.
    var isLuminary: Bool { self == .sun || self == .moon }

    var keywords: [String] {
        switch self {
        case .sun: return ["identity", "vitality", "purpose"]
        case .moon: return ["emotion", "needs", "instinct"]
        case .mercury: return ["mind", "speech", "learning"]
        case .venus: return ["love", "values", "taste"]
        case .mars: return ["drive", "desire", "anger"]
        case .jupiter: return ["growth", "luck", "belief"]
        case .saturn: return ["structure", "limits", "time"]
        case .uranus: return ["change", "freedom", "insight"]
        case .neptune: return ["dreams", "compassion", "illusion"]
        case .pluto: return ["power", "depth", "rebirth"]
        }
    }

    /// What this body governs, in plain language.
    var role: String {
        switch self {
        case .sun: return "Your core self — the will and vitality you're here to express."
        case .moon: return "Your inner world — what you need to feel safe and how you react."
        case .mercury: return "How you think, learn, and put things into words."
        case .venus: return "How you love, what you value, and what you find beautiful."
        case .mars: return "Your drive — how you pursue what you want and handle conflict."
        case .jupiter: return "Where you grow, take risks, and find meaning and luck."
        case .saturn: return "Where you meet limits, build structure, and earn mastery over time."
        case .uranus: return "Where you break patterns and need freedom and change."
        case .neptune: return "Where you dissolve boundaries — imagination, compassion, and illusion."
        case .pluto: return "Where you face power, loss, and deep transformation."
        }
    }

    /// How this body behaves placed in a given sign — grounded, sign-aware.
    func interpretation(in sign: ZodiacSign) -> String {
        switch self {
        case .sun:
            return "Your identity runs on \(sign.name)'s themes: \(sign.keywords.joined(separator: ", ")). \(sign.summary)"
        case .moon:
            return "You feel safest in a \(sign.name) key — \(sign.keywords.first ?? "steady") needs come first. Your reactions take on this sign's tempo."
        case .mercury:
            return "Your mind works in \(sign.name)'s style: you think and speak in a \(sign.keywords.first ?? "clear") way, ordering ideas the way this sign orders the world."
        case .venus:
            return "You love and value in \(sign.name)'s manner — drawn to what feels \(sign.keywords.first ?? "true"), and offering affection on those terms."
        case .mars:
            return "Your drive fires in \(sign.name)'s register: you pursue and assert yourself \(sign.keywords.first ?? "directly"), and your anger takes this shape too."
        case .jupiter:
            return "You grow through \(sign.name)'s gifts — luck and meaning arrive when you lean into being \(sign.keywords.first ?? "open")."
        case .saturn:
            return "Your lessons come dressed as \(sign.name): mastery is earned by maturing this sign's \(sign.keywords.first ?? "core") quality rather than avoiding it."
        case .uranus:
            return "You break new ground in \(sign.name)'s arena — a generational urge to reinvent what this sign represents."
        case .neptune:
            return "Your dreams and ideals take \(sign.name)'s color — a generational longing to spiritualize this sign's domain."
        case .pluto:
            return "Deep transformation works through \(sign.name)'s field — a generational drive to tear down and rebuild what this sign rules."
        }
    }
}
