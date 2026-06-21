import Foundation
import Observation

// MARK: - Equation Pool
// Format: "A op B = C" where A, B, C are 1–9, op is +/-/×/÷
// All fit in a 7-character display: [d][op][d][=][d] ... but we use 5-char: digit op digit = digit

let numbleEquations: [String] = [
    "1+1=2","1+2=3","1+3=4","1+4=5","1+5=6","1+6=7","1+7=8","1+8=9",
    "2+1=3","2+2=4","2+3=5","2+4=6","2+5=7","2+6=8","2+7=9",
    "3+1=4","3+2=5","3+3=6","3+4=7","3+5=8","3+6=9",
    "4+1=5","4+2=6","4+3=7","4+4=8","4+5=9",
    "5+1=6","5+2=7","5+3=8","5+4=9",
    "6+1=7","6+2=8","6+3=9",
    "7+1=8","7+2=9",
    "8+1=9",
    "9-1=8","9-2=7","9-3=6","9-4=5","9-5=4","9-6=3","9-7=2","9-8=1",
    "8-1=7","8-2=6","8-3=5","8-4=4","8-5=3","8-6=2","8-7=1",
    "7-1=6","7-2=5","7-3=4","7-4=3","7-5=2","7-6=1",
    "6-1=5","6-2=4","6-3=3","6-4=2","6-5=1",
    "5-1=4","5-2=3","5-3=2","5-4=1",
    "4-1=3","4-2=2","4-3=1",
    "3-1=2","3-2=1",
    "2-1=1",
    "2×2=4","2×3=6","2×4=8","3×2=6","3×3=9","4×2=8",
    "6÷2=3","8÷2=4","8÷4=2","9÷3=3","6÷3=2","4÷2=2",
]

// MARK: - Tile State

enum TileState {
    case empty, correct, present, absent
}

struct NumbleTile: Identifiable {
    let id = UUID()
    var char: Character = " "
    var state: TileState = .empty
}

struct NumbleRow: Identifiable {
    let id = UUID()
    var tiles: [NumbleTile]
    var submitted: Bool = false
}

// MARK: - Engine

@Observable
@MainActor
final class NumbleEngine {
    private(set) var target: String = ""
    private(set) var rows: [NumbleRow] = []
    private(set) var currentRow: Int = 0
    private(set) var isGameOver: Bool = false
    private(set) var isSolved: Bool = false
    private(set) var errorMessage: String = ""
    var maxAttempts: Int = 6

    private let equationLength = 5

    func startDaily() {
        let idx = dayIndex() % numbleEquations.count
        begin(numbleEquations[idx])
    }

    func startRandom() {
        begin(numbleEquations.randomElement()!)
    }

    private func begin(_ eq: String) {
        target = eq
        rows = (0..<maxAttempts).map { _ in
            NumbleRow(tiles: (0..<equationLength).map { _ in NumbleTile() })
        }
        currentRow = 0
        isGameOver = false
        isSolved = false
        errorMessage = ""
    }

    func typedChars() -> [Character] {
        rows[currentRow].tiles.map(\.char).filter { $0 != " " }
    }

    func currentInput() -> String {
        String(rows[currentRow].tiles.map(\.char))
    }

    func appendChar(_ c: Character) {
        guard !isGameOver else { return }
        let idx = rows[currentRow].tiles.firstIndex(where: { $0.char == " " })
        guard let i = idx else { return }
        rows[currentRow].tiles[i].char = c
        errorMessage = ""
    }

    func deleteChar() {
        guard !isGameOver else { return }
        let filled = rows[currentRow].tiles.filter { $0.char != " " }
        guard !filled.isEmpty else { return }
        let last = rows[currentRow].tiles.lastIndex(where: { $0.char != " " })!
        rows[currentRow].tiles[last].char = " "
    }

    func submit() {
        guard !isGameOver else { return }
        let guess = String(rows[currentRow].tiles.map(\.char))
        guard !guess.contains(" ") else { errorMessage = "Fill all 5 slots."; return }
        guard numbleEquations.contains(guess) else { errorMessage = "Not a valid equation."; return }

        let feedback = evaluate(guess: guess, target: target)
        for i in 0..<equationLength {
            rows[currentRow].tiles[i].state = feedback[i]
        }
        rows[currentRow].submitted = true

        if guess == target {
            isSolved = true
            isGameOver = true
        } else if currentRow == maxAttempts - 1 {
            isGameOver = true
        } else {
            currentRow += 1
        }
    }

    private func evaluate(guess: String, target: String) -> [TileState] {
        var result = Array(repeating: TileState.absent, count: equationLength)
        let gArr = Array(guess)
        let tArr = Array(target)
        var tUsed = Array(repeating: false, count: equationLength)

        for i in 0..<equationLength where gArr[i] == tArr[i] {
            result[i] = .correct
            tUsed[i] = true
        }
        for i in 0..<equationLength where result[i] != .correct {
            for j in 0..<equationLength where !tUsed[j] && result[j] != .correct && gArr[i] == tArr[j] {
                result[i] = .present
                tUsed[j] = true
                break
            }
        }
        return result
    }

    private func dayIndex() -> Int {
        let ref = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: 0))
        let today = Calendar.current.startOfDay(for: Date())
        return Calendar.current.dateComponents([.day], from: ref, to: today).day ?? 0
    }

    var charStates: [Character: TileState] {
        var states: [Character: TileState] = [:]
        for row in rows where row.submitted {
            for tile in row.tiles {
                let c = tile.char
                if let existing = states[c] {
                    if existing == .correct { continue }
                    if tile.state == .correct || (tile.state == .present && existing == .absent) {
                        states[c] = tile.state
                    }
                } else {
                    states[c] = tile.state
                }
            }
        }
        return states
    }
}
