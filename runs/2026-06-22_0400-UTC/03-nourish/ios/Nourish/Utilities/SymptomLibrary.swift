import Foundation

// MARK: - SymptomCategory

enum SymptomCategory: String, CaseIterable, Identifiable {
    case gi = "GI"
    case skin = "Skin"
    case head = "Head"
    case energy = "Energy"
    case joint = "Joint"
    case respiratory = "Respiratory"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .gi: return "stomach"
        case .skin: return "hand.raised.fill"
        case .head: return "brain.head.profile"
        case .energy: return "bolt.fill"
        case .joint: return "figure.walk"
        case .respiratory: return "lungs.fill"
        }
    }

    var emoji: String {
        switch self {
        case .gi: return "🫃"
        case .skin: return "🖐"
        case .head: return "🧠"
        case .energy: return "⚡"
        case .joint: return "🦴"
        case .respiratory: return "🫁"
        }
    }
}

// MARK: - SymptomItem

struct SymptomItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: SymptomCategory
}

// MARK: - SymptomLibrary

enum SymptomLibrary {

    static let all: [SymptomItem] = gi + skin + head + energy + joint + respiratory

    static let gi: [SymptomItem] = [
        SymptomItem(name: "Bloating", category: .gi),
        SymptomItem(name: "Gas", category: .gi),
        SymptomItem(name: "Diarrhea", category: .gi),
        SymptomItem(name: "Constipation", category: .gi),
        SymptomItem(name: "Stomach Cramps", category: .gi),
        SymptomItem(name: "Nausea", category: .gi),
        SymptomItem(name: "Acid Reflux", category: .gi),
        SymptomItem(name: "IBS Flare", category: .gi),
    ]

    static let skin: [SymptomItem] = [
        SymptomItem(name: "Hives", category: .skin),
        SymptomItem(name: "Eczema Flare", category: .skin),
        SymptomItem(name: "Rash", category: .skin),
        SymptomItem(name: "Acne", category: .skin),
        SymptomItem(name: "Swelling", category: .skin),
        SymptomItem(name: "Itching", category: .skin),
    ]

    static let head: [SymptomItem] = [
        SymptomItem(name: "Headache", category: .head),
        SymptomItem(name: "Migraine", category: .head),
        SymptomItem(name: "Brain Fog", category: .head),
        SymptomItem(name: "Dizziness", category: .head),
    ]

    static let energy: [SymptomItem] = [
        SymptomItem(name: "Fatigue", category: .energy),
        SymptomItem(name: "Energy Crash", category: .energy),
        SymptomItem(name: "Poor Sleep", category: .energy),
        SymptomItem(name: "Insomnia", category: .energy),
    ]

    static let joint: [SymptomItem] = [
        SymptomItem(name: "Joint Pain", category: .joint),
        SymptomItem(name: "Muscle Aches", category: .joint),
        SymptomItem(name: "Stiffness", category: .joint),
    ]

    static let respiratory: [SymptomItem] = [
        SymptomItem(name: "Runny Nose", category: .respiratory),
        SymptomItem(name: "Congestion", category: .respiratory),
        SymptomItem(name: "Sneezing", category: .respiratory),
        SymptomItem(name: "Asthma Symptoms", category: .respiratory),
    ]

    static func search(_ query: String) -> [SymptomItem] {
        guard !query.isEmpty else { return all }
        let lower = query.lowercased()
        return all.filter { $0.name.lowercased().contains(lower) }
    }

    static func items(in category: SymptomCategory) -> [SymptomItem] {
        all.filter { $0.category == category }
    }
}
