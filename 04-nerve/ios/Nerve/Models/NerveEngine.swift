import Foundation

enum PegColor: Int, CaseIterable, Identifiable {
    case red = 0, orange, yellow, green, blue, purple, pink, white

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .red: return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .pink: return "Pink"
        case .white: return "White"
        }
    }
}

enum Difficulty: String, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var id: String { rawValue }
    var codeLength: Int { self == .easy ? 4 : self == .medium ? 4 : 5 }
    var colorCount: Int { self == .easy ? 6 : self == .medium ? 8 : 8 }
    var allowDuplicates: Bool { self != .easy }

    var description: String {
        switch self {
        case .easy: return "4 pegs · 6 colors · no duplicates"
        case .medium: return "4 pegs · 8 colors · duplicates allowed"
        case .hard: return "5 pegs · 8 colors · duplicates allowed"
        }
    }
}

enum NerveEngine {
    static let maxGuesses = 12

    static func generateCode(difficulty: Difficulty, seed: UInt64? = nil) -> [Int] {
        let length = difficulty.codeLength
        let colors = difficulty.colorCount
        var rng = seed.map { SplitMix64(seed: $0) } ?? SplitMix64(seed: UInt64(Date().timeIntervalSince1970))
        var code: [Int] = []
        if difficulty.allowDuplicates {
            for _ in 0..<length {
                code.append(Int(rng.next() % UInt64(colors)))
            }
        } else {
            var available = Array(0..<colors)
            for _ in 0..<length {
                let idx = Int(rng.next() % UInt64(available.count))
                code.append(available[idx])
                available.remove(at: idx)
            }
        }
        return code
    }

    static func evaluate(guess: [Int], secret: [Int]) -> (black: Int, white: Int) {
        guard guess.count == secret.count else { return (0, 0) }
        var black = 0
        var secretCounts: [Int: Int] = [:]
        var guessCounts: [Int: Int] = [:]
        for i in 0..<secret.count {
            if guess[i] == secret[i] {
                black += 1
            } else {
                secretCounts[secret[i], default: 0] += 1
                guessCounts[guess[i], default: 0] += 1
            }
        }
        var white = 0
        for (color, count) in guessCounts {
            white += min(count, secretCounts[color, default: 0])
        }
        return (black, white)
    }

    // Encode feedback as two-element array [black, white]
    static func encodeFeedback(black: Int, white: Int) -> [Int] { [black, white] }

    static func dailySeed(for date: Date = Date()) -> UInt64 {
        let cal = Calendar(identifier: .gregorian)
        let components = cal.dateComponents([.year, .month, .day], from: date)
        let y = UInt64(components.year ?? 2026)
        let m = UInt64(components.month ?? 1)
        let d = UInt64(components.day ?? 1)
        // FNV-1a inspired mixing
        var h: UInt64 = 14695981039346656037
        for v in [y, m, d] {
            h ^= v
            h = h &* 1099511628211
        }
        return h
    }
}

// PRNG used for reproducible daily codes
struct SplitMix64 {
    var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state = state &+ 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
