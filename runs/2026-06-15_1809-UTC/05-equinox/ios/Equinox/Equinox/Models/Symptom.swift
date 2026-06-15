import Foundation

/// Clinically-grounded symptom domains in the spirit of the Greene Climacteric Scale.
enum SymptomDomain: String, CaseIterable, Identifiable {
    case vasomotor = "Vasomotor"
    case psychological = "Psychological"
    case somatic = "Somatic"
    case sexual = "Sexual & other"

    var id: String { rawValue }

    var caption: String {
        switch self {
        case .vasomotor: return "Heat & circulation"
        case .psychological: return "Mood & mind"
        case .somatic: return "Body & energy"
        case .sexual: return "Intimacy & other"
        }
    }

    var symbol: String {
        switch self {
        case .vasomotor: return "thermometer.sun.fill"
        case .psychological: return "brain.head.profile"
        case .somatic: return "figure.walk"
        case .sexual: return "heart.fill"
        }
    }
}

/// A single tracked symptom. `key` is stable and used as the JSON dictionary key.
struct Symptom: Identifiable, Hashable {
    let key: String
    let name: String
    let domain: SymptomDomain

    var id: String { key }
}

/// Severity 0–3 per symptom (0 = none/not tracked, 1 = mild, 2 = moderate, 3 = severe).
enum Severity: Int, CaseIterable, Identifiable {
    case none = 0
    case mild = 1
    case moderate = 2
    case severe = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .none: return "None"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        }
    }
}

/// The static symptom catalog (in code), grouped by domain.
enum SymptomCatalog {
    static let all: [Symptom] = [
        // Vasomotor
        Symptom(key: "hot_flashes", name: "Hot flashes", domain: .vasomotor),
        Symptom(key: "night_sweats", name: "Night sweats", domain: .vasomotor),
        Symptom(key: "palpitations", name: "Heart palpitations", domain: .vasomotor),
        // Psychological
        Symptom(key: "mood_swings", name: "Mood swings", domain: .psychological),
        Symptom(key: "anxiety", name: "Anxiety", domain: .psychological),
        Symptom(key: "irritability", name: "Irritability", domain: .psychological),
        Symptom(key: "low_mood", name: "Low mood", domain: .psychological),
        Symptom(key: "brain_fog", name: "Brain fog", domain: .psychological),
        // Somatic
        Symptom(key: "sleep_problems", name: "Sleep problems", domain: .somatic),
        Symptom(key: "fatigue", name: "Fatigue", domain: .somatic),
        Symptom(key: "joint_aches", name: "Joint & muscle aches", domain: .somatic),
        Symptom(key: "headaches", name: "Headaches", domain: .somatic),
        Symptom(key: "dizziness", name: "Dizziness", domain: .somatic),
        // Sexual & other
        Symptom(key: "vaginal_dryness", name: "Vaginal dryness", domain: .sexual),
        Symptom(key: "low_libido", name: "Low libido", domain: .sexual)
    ]

    /// A compact, commonly-relevant subset surfaced by default on Today.
    static let commonKeys: Set<String> = [
        "mood_swings", "anxiety", "sleep_problems", "fatigue", "joint_aches", "brain_fog"
    ]

    static func symptoms(in domain: SymptomDomain) -> [Symptom] {
        all.filter { $0.domain == domain }
    }

    static func symptom(forKey key: String) -> Symptom? {
        all.first { $0.key == key }
    }

    static func name(forKey key: String) -> String {
        symptom(forKey: key)?.name ?? key
    }

    static func domain(forKey key: String) -> SymptomDomain? {
        symptom(forKey: key)?.domain
    }
}

/// A small curated catalog of treatments / supplements a user might log.
enum TreatmentCatalog {
    static let all: [String] = [
        "HRT (estrogen)",
        "HRT (progesterone)",
        "Vaginal estrogen",
        "Non-hormonal Rx",
        "SSRI / SNRI",
        "Black cohosh",
        "Soy / isoflavones",
        "Vitamin D",
        "Calcium",
        "Magnesium",
        "Omega-3",
        "Evening primrose",
        "CBT / therapy",
        "Acupuncture"
    ]
}
