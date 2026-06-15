import Foundation

/// A Learn-library article. Content is authored in-code: accurate, non-prescriptive,
/// and consistently framed around "talk to your clinician."
struct Article: Identifiable, Hashable {
    let id: String
    let category: LearnCategory
    let title: String
    let summary: String
    let readMinutes: Int
    let isPro: Bool
    /// Body as an ordered list of sections (heading + paragraphs).
    let sections: [ArticleSection]

    static func == (lhs: Article, rhs: Article) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct ArticleSection: Identifiable, Hashable {
    let id = UUID()
    let heading: String
    let paragraphs: [String]
}

enum LearnCategory: String, CaseIterable, Identifiable {
    case vasomotor = "Hot flashes & night sweats"
    case sleep = "Sleep"
    case mood = "Mood & mind"
    case hormones = "Hormones & HRT"
    case longTerm = "Bone & heart health"
    case lifestyle = "Lifestyle"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .vasomotor: return "thermometer.sun.fill"
        case .sleep: return "moon.stars.fill"
        case .mood: return "brain.head.profile"
        case .hormones: return "pills.fill"
        case .longTerm: return "heart.fill"
        case .lifestyle: return "figure.walk"
        }
    }

    var blurb: String {
        switch self {
        case .vasomotor: return "Why heat happens, common triggers, and what helps."
        case .sleep: return "Night sweats, restless nights, and rebuilding rest."
        case .mood: return "Anxiety, low mood, and brain fog in midlife."
        case .hormones: return "A plain-language look at HRT and alternatives."
        case .longTerm: return "Protecting your bones and heart for the years ahead."
        case .lifestyle: return "Movement, food, and cooling that genuinely help."
        }
    }
}
