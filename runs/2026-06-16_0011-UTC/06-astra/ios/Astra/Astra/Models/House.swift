import Foundation

/// The twelve houses. Astra uses the Whole-Sign system: the Ascendant's whole sign
/// becomes the 1st house, and each following sign is the next house in order.
enum House: Int, CaseIterable, Identifiable {
    case first = 1, second, third, fourth, fifth, sixth
    case seventh, eighth, ninth, tenth, eleventh, twelfth

    var id: Int { rawValue }

    var ordinal: String {
        switch self {
        case .first: return "1st"
        case .second: return "2nd"
        case .third: return "3rd"
        case .fourth: return "4th"
        case .fifth: return "5th"
        case .sixth: return "6th"
        case .seventh: return "7th"
        case .eighth: return "8th"
        case .ninth: return "9th"
        case .tenth: return "10th"
        case .eleventh: return "11th"
        case .twelfth: return "12th"
        }
    }

    var title: String {
        switch self {
        case .first: return "Self & Body"
        case .second: return "Money & Values"
        case .third: return "Mind & Siblings"
        case .fourth: return "Home & Roots"
        case .fifth: return "Joy & Creation"
        case .sixth: return "Work & Health"
        case .seventh: return "Partnership"
        case .eighth: return "Depth & Shared Resources"
        case .ninth: return "Meaning & Travel"
        case .tenth: return "Career & Public Life"
        case .eleventh: return "Community & Hopes"
        case .twelfth: return "Solitude & The Unseen"
        }
    }

    var meaning: String {
        switch self {
        case .first: return "How you show up — your manner, your body, the first impression you make."
        case .second: return "What you own and what you're worth to yourself; income, security, and values."
        case .third: return "Everyday thinking, talking, writing, short trips, siblings, and neighbors."
        case .fourth: return "Home, family, ancestry, and the private base you return to."
        case .fifth: return "Play, romance, children, art — anything you create for the joy of it."
        case .sixth: return "Daily work, routines, service, health, and the systems that keep you running."
        case .seventh: return "One-to-one partnership — marriage, close allies, and open enemies alike."
        case .eighth: return "Intimacy, other people's money, loss, sex, and deep transformation."
        case .ninth: return "Beliefs, higher study, long journeys, and the search for meaning."
        case .tenth: return "Career, reputation, authority, and your visible mark on the world."
        case .eleventh: return "Friends, networks, causes, and the future you hope toward."
        case .twelfth: return "Rest, retreat, the unconscious, and what works behind the scenes."
        }
    }

    /// Whole-sign house number for a body, given the Ascendant's sign.
    static func wholeSign(for bodySign: ZodiacSign, ascendant: ZodiacSign) -> House {
        let offset = ((bodySign.rawValue - ascendant.rawValue) + 12) % 12
        return House(rawValue: offset + 1) ?? .first
    }
}
