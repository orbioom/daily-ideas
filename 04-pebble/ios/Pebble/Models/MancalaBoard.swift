import Foundation

struct MancalaBoard: Equatable {
    // pits[0..5]  = player 0 pits (left to right from player 0's perspective)
    // pits[6]     = player 0's store
    // pits[7..12] = player 1 pits (right to left from player 0's perspective;
    //               pit 7 is directly opposite pit 5)
    // pits[13]    = player 1's store
    var pits: [Int]
    var currentPlayer: Int = 0  // 0 or 1
    var isGameOver: Bool = false
    var winner: Int? = nil       // nil = draw, 0 or 1

    static let playerOnePits = 0...5
    static let playerTwoPits = 7...12
    static let playerOneStore = 6
    static let playerTwoStore = 13

    init(stonesPerPit: Int = 4) {
        pits = Array(repeating: stonesPerPit, count: 14)
        pits[6] = 0    // stores start empty
        pits[13] = 0
    }

    var playerOneScore: Int { pits[6] }
    var playerTwoScore: Int { pits[13] }

    func validMoves(for player: Int) -> [Int] {
        let range = player == 0 ? 0...5 : 7...12
        return range.filter { pits[$0] > 0 }
    }

    // Returns true if the current player gets an extra turn.
    mutating func sow(pit: Int) -> Bool {
        guard pits[pit] > 0 else { return false }
        var stones = pits[pit]
        pits[pit] = 0
        var idx = pit
        let enemyStore = currentPlayer == 0 ? 13 : 6

        while stones > 0 {
            idx = (idx + 1) % 14
            if idx == enemyStore { continue }  // skip opponent's store
            pits[idx] += 1
            stones -= 1
        }

        // Capture: last stone lands in own empty pit on own side.
        let ownRange = currentPlayer == 0 ? 0...5 : 7...12
        let ownStore = currentPlayer == 0 ? 6 : 13
        if ownRange.contains(idx) && pits[idx] == 1 {
            let opposite = 12 - idx
            if pits[opposite] > 0 {
                pits[ownStore] += pits[opposite] + 1
                pits[idx] = 0
                pits[opposite] = 0
            }
        }

        // Extra turn: last stone lands in own store.
        let extraTurn = (idx == ownStore)

        if !extraTurn {
            currentPlayer = 1 - currentPlayer
        }

        checkGameOver()
        return extraTurn
    }

    mutating func checkGameOver() {
        let p0Empty = (0...5).allSatisfy { pits[$0] == 0 }
        let p1Empty = (7...12).allSatisfy { pits[$0] == 0 }
        if p0Empty || p1Empty {
            // Sweep remaining stones to each player's store.
            for i in 0...5   { pits[6]  += pits[i]; pits[i] = 0 }
            for i in 7...12  { pits[13] += pits[i]; pits[i] = 0 }
            isGameOver = true
            if pits[6] > pits[13]      { winner = 0 }
            else if pits[13] > pits[6] { winner = 1 }
            else                       { winner = nil }
        }
    }
}
