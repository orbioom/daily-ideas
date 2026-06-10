import Foundation
import SwiftData
import SwiftUI

enum LetterState: String, Codable {
    case empty, absent, present, correct

    var tint: Color {
        switch self {
        case .empty: return Brand.dynamic(0xDCDEE6, 0x262931)
        case .absent: return Brand.dynamic(0x9BA0B0, 0x4A4E5A)
        case .present: return Brand.dynamic(0xC79A4B, 0xD8B45E)
        case .correct: return Brand.dynamic(0x4FB98C, 0x5FC78C)
        }
    }
    var filled: Bool { self != .empty }
    /// Used to merge keyboard hints (correct beats present beats absent).
    var rank: Int {
        switch self { case .empty: 0; case .absent: 1; case .present: 2; case .correct: 3 }
    }
    var emoji: String {
        switch self { case .correct: "🟩"; case .present: "🟨"; default: "⬛️" }
    }
}

enum GameMode: String, Codable { case daily, unlimited }
enum GameState: String, Codable { case playing, won, lost }

/// A single Lexic game, persisted so the daily resumes and stats accrue.
@Model
final class WordGame {
    var id: UUID
    var answer: String
    var guessesJoined: String     // comma-separated guesses
    var modeRaw: String
    var stateRaw: String
    var hardMode: Bool
    var dailyKey: String          // "yyyy-MM-dd" for daily games, else ""
    var startedAt: Date
    var finishedAt: Date?

    init(answer: String, mode: GameMode, hardMode: Bool, dailyKey: String = "") {
        self.id = UUID()
        self.answer = answer
        self.guessesJoined = ""
        self.modeRaw = mode.rawValue
        self.stateRaw = GameState.playing.rawValue
        self.hardMode = hardMode
        self.dailyKey = dailyKey
        self.startedAt = .now
        self.finishedAt = nil
    }

    var mode: GameMode { GameMode(rawValue: modeRaw) ?? .unlimited }
    var state: GameState {
        get { GameState(rawValue: stateRaw) ?? .playing }
        set { stateRaw = newValue.rawValue }
    }

    var guesses: [String] {
        get { guessesJoined.isEmpty ? [] : guessesJoined.split(separator: ",").map(String.init) }
        set { guessesJoined = newValue.joined(separator: ",") }
    }

    var isFinished: Bool { state != .playing }
    var guessCount: Int { guesses.count }
}
