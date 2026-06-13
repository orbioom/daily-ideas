import Foundation
import SwiftUI

enum TriviaCategory: String, CaseIterable, Identifiable, Codable {
    case science, history, geography, arts, sports, screen, music, nature, tech, food
    var id: String { rawValue }
    var label: String {
        switch self {
        case .science: return "Science"
        case .history: return "History"
        case .geography: return "Geography"
        case .arts: return "Arts & Lit"
        case .sports: return "Sports"
        case .screen: return "Film & TV"
        case .music: return "Music"
        case .nature: return "Nature"
        case .tech: return "Tech"
        case .food: return "Food & Drink"
        }
    }
    var icon: String {
        switch self {
        case .science: return "atom"
        case .history: return "building.columns.fill"
        case .geography: return "globe.americas.fill"
        case .arts: return "book.fill"
        case .sports: return "sportscourt.fill"
        case .screen: return "film.fill"
        case .music: return "music.note"
        case .nature: return "leaf.fill"
        case .tech: return "cpu.fill"
        case .food: return "fork.knife"
        }
    }
    var colorIndex: Int { TriviaCategory.allCases.firstIndex(of: self) ?? 0 }
}

enum Difficulty: Int, CaseIterable, Identifiable, Codable {
    case easy = 1, medium = 2, hard = 3
    var id: Int { rawValue }
    var label: String { ["", "Easy", "Medium", "Hard"][rawValue] }
    var points: Int { rawValue * 100 }
}

struct TriviaQuestion: Identifiable {
    let id: Int
    let category: TriviaCategory
    let difficulty: Difficulty
    let prompt: String
    let choices: [String]      // exactly 4
    let answerIndex: Int       // 0…3
    let fact: String

    var answer: String { choices[answerIndex] }
}
