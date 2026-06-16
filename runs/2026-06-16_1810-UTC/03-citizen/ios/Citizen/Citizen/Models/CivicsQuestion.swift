import Foundation

/// The three top-level USCIS civics categories, with their official subsections.
enum CivicsCategory: String, CaseIterable, Identifiable, Codable {
    case americanGovernment
    case americanHistory
    case integratedCivics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .americanGovernment: return "American Government"
        case .americanHistory: return "American History"
        case .integratedCivics: return "Integrated Civics"
        }
    }

    var shortTitle: String {
        switch self {
        case .americanGovernment: return "Government"
        case .americanHistory: return "History"
        case .integratedCivics: return "Civics"
        }
    }

    var systemImage: String {
        switch self {
        case .americanGovernment: return "building.columns"
        case .americanHistory: return "book.closed"
        case .integratedCivics: return "flag"
        }
    }
}

/// The official USCIS subsection a question belongs to (for finer grouping/filters).
enum CivicsSection: String, CaseIterable, Identifiable, Codable {
    case principlesOfDemocracy
    case systemOfGovernment
    case rightsAndResponsibilities
    case colonialAndIndependence
    case eighteenHundreds
    case recentAndOther
    case geography
    case symbols
    case holidays

    var id: String { rawValue }

    var title: String {
        switch self {
        case .principlesOfDemocracy: return "Principles of American Democracy"
        case .systemOfGovernment: return "System of Government"
        case .rightsAndResponsibilities: return "Rights & Responsibilities"
        case .colonialAndIndependence: return "Colonial Period & Independence"
        case .eighteenHundreds: return "The 1800s"
        case .recentAndOther: return "Recent American History & Other"
        case .geography: return "Geography"
        case .symbols: return "Symbols"
        case .holidays: return "Holidays"
        }
    }

    var category: CivicsCategory {
        switch self {
        case .principlesOfDemocracy, .systemOfGovernment, .rightsAndResponsibilities:
            return .americanGovernment
        case .colonialAndIndependence, .eighteenHundreds, .recentAndOther:
            return .americanHistory
        case .geography, .symbols, .holidays:
            return .integratedCivics
        }
    }
}

/// One of the official USCIS 100 civics questions (2008 version).
///
/// Pure value type, authored as a bundled fixture (see `CivicsContent`).
struct CivicsQuestion: Identifiable, Hashable, Codable {
    /// Official question number, 1...100. Serves as stable identity.
    let number: Int
    let section: CivicsSection
    let prompt: String
    /// Canonical acceptable answers. For `varies` questions these are examples/guidance.
    let acceptableAnswers: [String]
    /// Optional clarifying note (e.g. "Answer for YOUR state").
    let note: String?
    /// True when the correct answer depends on the user's state or current officeholders/date.
    let varies: Bool

    var id: Int { number }
    var category: CivicsCategory { section.category }

    init(number: Int,
         section: CivicsSection,
         prompt: String,
         acceptableAnswers: [String],
         note: String? = nil,
         varies: Bool = false) {
        self.number = number
        self.section = section
        self.prompt = prompt
        self.acceptableAnswers = acceptableAnswers
        self.note = note
        self.varies = varies
    }

    /// A single representative answer for display (first acceptable answer).
    var primaryAnswer: String {
        acceptableAnswers.first ?? "—"
    }
}

/// A word from the official USCIS reading or writing vocabulary lists.
struct VocabWord: Identifiable, Hashable, Codable {
    enum List: String, CaseIterable, Codable, Identifiable {
        case reading
        case writing
        var id: String { rawValue }
        var title: String { self == .reading ? "Reading Vocabulary" : "Writing Vocabulary" }
    }

    enum Group: String, CaseIterable, Codable, Identifiable {
        case people, civics, places, holidays, questionWords, verbs, other
        var id: String { rawValue }
        var title: String {
            switch self {
            case .people: return "People"
            case .civics: return "Civics"
            case .places: return "Places"
            case .holidays: return "Holidays"
            case .questionWords: return "Question Words"
            case .verbs: return "Verbs"
            case .other: return "Other (Function Words)"
            }
        }
    }

    let word: String
    let list: List
    let group: Group

    var id: String { "\(list.rawValue)-\(word)" }
}
