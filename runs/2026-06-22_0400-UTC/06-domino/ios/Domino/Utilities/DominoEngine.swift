import Foundation
import Observation

@Observable
final class DominoEngine {
    // MARK: - State
    var playerHand: [DominoTile] = []
    var aiHand: [DominoTile] = []
    var chain: [PlacedTile] = []
    var boneyard: [DominoTile] = []
    var leftEnd: Int = 0
    var rightEnd: Int = 0
    var playerScore: Int = 0
    var aiScore: Int = 0
    var isPlayerTurn: Bool = true
    var phase: GamePhase = .setup
    var roundResult: RoundResult? = nil
    var consecutivePasses: Int = 0
    var difficulty: AIDifficulty = .medium
    var isAIThinking: Bool = false
    var matchPointTarget: Int = 100
    var roundsPlayed: Int = 0
    var matchStartTime: Date = Date()
    var showAIHand: Bool = false

    // MARK: - Types

    enum GamePhase {
        case setup, playing, roundOver, matchOver
    }

    enum AIDifficulty: String, CaseIterable {
        case easy = "easy"
        case medium = "medium"
        case hard = "hard"

        var displayName: String {
            switch self {
            case .easy: return "Easy"
            case .medium: return "Medium"
            case .hard: return "Hard"
            }
        }
    }

    struct PlacedTile: Identifiable {
        let id: UUID
        let tile: DominoTile
        let isDouble: Bool
        let leftPip: Int
        let rightPip: Int
    }

    struct RoundResult {
        let playerRoundScore: Int
        let aiRoundScore: Int
        let winner: String  // "player", "ai", or "blocked"
        let reason: String
    }

    enum ChainEnd {
        case left, right
    }

    // MARK: - Match / Round Control

    func newMatch(difficulty: AIDifficulty, matchPointTarget: Int = 100) {
        self.difficulty = difficulty
        self.matchPointTarget = matchPointTarget
        self.playerScore = 0
        self.aiScore = 0
        self.roundsPlayed = 0
        self.matchStartTime = Date()
        newRound()
    }

    func newRound() {
        roundsPlayed += 1
        chain = []
        consecutivePasses = 0
        roundResult = nil
        leftEnd = 0
        rightEnd = 0

        // Shuffle and deal
        var tiles = DominoTile.fullSet.shuffled()
        playerHand = Array(tiles.prefix(7))
        tiles.removeFirst(7)
        aiHand = Array(tiles.prefix(7))
        tiles.removeFirst(7)
        boneyard = tiles  // 14 tiles remain

        // Determine first player
        isPlayerTurn = determineFirstPlayer()
        phase = .playing

        // If AI goes first, trigger AI turn
        if !isPlayerTurn {
            Task {
                await aiTurn()
            }
        }
    }

    private func determineFirstPlayer() -> Bool {
        // Find highest double in each hand
        let playerHighestDouble = playerHand
            .filter { $0.isDouble }
            .max(by: { $0.totalPips < $1.totalPips })

        let aiHighestDouble = aiHand
            .filter { $0.isDouble }
            .max(by: { $0.totalPips < $1.totalPips })

        // Both have doubles
        if let phd = playerHighestDouble, let ahd = aiHighestDouble {
            if phd.totalPips >= ahd.totalPips {
                return true  // player goes first
            } else {
                return false
            }
        }

        // Only player has doubles
        if playerHighestDouble != nil { return true }
        // Only AI has doubles
        if aiHighestDouble != nil { return false }

        // No doubles — compare highest tile
        let playerHighest = playerHand.max(by: { $0.totalPips < $1.totalPips })
        let aiHighest = aiHand.max(by: { $0.totalPips < $1.totalPips })

        let pTotal = playerHighest?.totalPips ?? 0
        let aTotal = aiHighest?.totalPips ?? 0
        return pTotal >= aTotal
    }

    // MARK: - Valid Moves

    func validMoves(hand: [DominoTile]) -> [(tile: DominoTile, end: ChainEnd)] {
        if chain.isEmpty {
            // Any tile can be played on an empty chain; use .right as canonical end
            return hand.map { ($0, .right) }
        }

        var moves: [(tile: DominoTile, end: ChainEnd)] = []
        for tile in hand {
            if tile.canConnect(to: leftEnd) {
                moves.append((tile, .left))
            }
            if tile.canConnect(to: rightEnd) {
                moves.append((tile, .right))
            }
        }

        // Deduplicate: when leftEnd == rightEnd, same tile appears as both .left and .right;
        // keep both so the player can choose which end. Dedup only exact tile+end pairs.
        var seen = Set<String>()
        return moves.filter { move in
            let key = "\(move.tile.id)_\(move.end)"
            return seen.insert(key).inserted
        }
    }

    func hasValidMove(hand: [DominoTile]) -> Bool {
        !validMoves(hand: hand).isEmpty
    }

    func isBlocked() -> Bool {
        boneyard.isEmpty &&
        !hasValidMove(hand: playerHand) &&
        !hasValidMove(hand: aiHand)
    }

    // MARK: - Player Actions

    @discardableResult
    func playerPlay(tile: DominoTile, onEnd: ChainEnd) -> Bool {
        guard phase == .playing, isPlayerTurn else { return false }

        // Validate the move
        if chain.isEmpty {
            guard playerHand.contains(tile) else { return false }
        } else {
            let moves = validMoves(hand: playerHand)
            let isValid = moves.contains { $0.tile == tile && $0.end == onEnd }
            guard isValid else { return false }
        }

        // Remove from hand
        playerHand.removeAll { $0 == tile }

        // Place on chain
        placeTileOnChain(tile: tile, onEnd: chain.isEmpty ? .right : onEnd)
        consecutivePasses = 0

        // Check for round end
        if playerHand.isEmpty {
            resolveRound()
            return true
        }

        if isBlocked() {
            resolveRound()
            return true
        }

        isPlayerTurn = false

        // Trigger AI turn
        Task {
            await aiTurn()
        }

        return true
    }

    @discardableResult
    func playerDraw() -> DominoTile? {
        guard phase == .playing, isPlayerTurn, !boneyard.isEmpty else { return nil }

        let tile = boneyard.removeFirst()
        playerHand.append(tile)
        return tile
    }

    func playerPass() {
        guard phase == .playing, isPlayerTurn else { return }
        guard boneyard.isEmpty && !hasValidMove(hand: playerHand) else { return }

        consecutivePasses += 1

        if consecutivePasses >= 2 || isBlocked() {
            resolveRound()
            return
        }

        isPlayerTurn = false
        Task {
            await aiTurn()
        }
    }

    // MARK: - AI Turn

    @MainActor
    func aiTurn() async {
        guard phase == .playing, !isPlayerTurn else { return }

        isAIThinking = true

        // Realistic thinking delay
        let delay = Double.random(in: 1.0...1.5)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        guard phase == .playing else {
            isAIThinking = false
            return
        }

        let moves = validMoves(hand: aiHand)

        if moves.isEmpty {
            // Draw from boneyard if possible
            if !boneyard.isEmpty {
                let tile = boneyard.removeFirst()
                aiHand.append(tile)

                // Check if can play now
                let newMoves = validMoves(hand: aiHand)
                if newMoves.isEmpty {
                    isAIThinking = false
                    // Try drawing again next turn if boneyard not empty
                    if boneyard.isEmpty {
                        consecutivePasses += 1
                        if consecutivePasses >= 2 || isBlocked() {
                            resolveRound()
                            return
                        }
                        isPlayerTurn = true
                    } else {
                        // Keep drawing
                        isPlayerTurn = false
                        Task {
                            await aiTurn()
                        }
                        return
                    }
                } else {
                    // Play the newly drawn tile if possible
                    if let chosen = DominoAI.chooseMove(
                        hand: aiHand,
                        validMoves: newMoves,
                        playerHandCount: playerHand.count,
                        difficulty: difficulty
                    ) {
                        aiHand.removeAll { $0 == chosen.tile }
                        placeTileOnChain(tile: chosen.tile, onEnd: chain.isEmpty ? .right : chosen.end)
                        consecutivePasses = 0

                        if aiHand.isEmpty {
                            isAIThinking = false
                            resolveRound()
                            return
                        }

                        if isBlocked() {
                            isAIThinking = false
                            resolveRound()
                            return
                        }

                        isPlayerTurn = true
                    }
                }
            } else {
                // Boneyard empty, AI must pass
                consecutivePasses += 1
                if consecutivePasses >= 2 || isBlocked() {
                    isAIThinking = false
                    resolveRound()
                    return
                }
                isPlayerTurn = true
            }
        } else {
            // AI has valid moves — choose one
            if let chosen = DominoAI.chooseMove(
                hand: aiHand,
                validMoves: moves,
                playerHandCount: playerHand.count,
                difficulty: difficulty
            ) {
                aiHand.removeAll { $0 == chosen.tile }
                placeTileOnChain(tile: chosen.tile, onEnd: chain.isEmpty ? .right : chosen.end)
                consecutivePasses = 0

                if aiHand.isEmpty {
                    isAIThinking = false
                    resolveRound()
                    return
                }

                if isBlocked() {
                    isAIThinking = false
                    resolveRound()
                    return
                }

                isPlayerTurn = true
            }
        }

        isAIThinking = false
    }

    // MARK: - Chain Placement

    private func placeTileOnChain(tile: DominoTile, onEnd: ChainEnd) {
        if chain.isEmpty {
            // First tile — set both ends
            let lp: Int
            let rp: Int
            if tile.isDouble {
                lp = tile.a
                rp = tile.a
            } else {
                lp = tile.a
                rp = tile.b
            }
            leftEnd = lp
            rightEnd = rp
            let placed = PlacedTile(
                id: UUID(),
                tile: tile,
                isDouble: tile.isDouble,
                leftPip: lp,
                rightPip: rp
            )
            chain.append(placed)
        } else if onEnd == .right {
            // Connect to right end
            let oriented = tile.oriented(rightEnd: rightEnd)
            let newRight = oriented.left  // the non-matching side becomes the new open end
            // Actually: matching side goes adjacent to the chain, free side is the new end
            // oriented.right == rightEnd (matching side), oriented.left is the new open end
            let placed = PlacedTile(
                id: UUID(),
                tile: tile,
                isDouble: tile.isDouble,
                leftPip: oriented.left,
                rightPip: oriented.right
            )
            chain.append(placed)
            rightEnd = tile.isDouble ? oriented.right : oriented.left
        } else {
            // Connect to left end
            let oriented = tile.orientedLeft(leftEnd: leftEnd)
            // oriented.left == leftEnd (matching side), oriented.right is the new open end
            let placed = PlacedTile(
                id: UUID(),
                tile: tile,
                isDouble: tile.isDouble,
                leftPip: oriented.left,
                rightPip: oriented.right
            )
            chain.insert(placed, at: 0)
            leftEnd = tile.isDouble ? oriented.left : oriented.right
        }
    }

    // MARK: - Round Resolution

    private func resolveRound() {
        phase = .roundOver

        let playerPips = playerHand.reduce(0) { $0 + $1.totalPips }
        let aiPips = aiHand.reduce(0) { $0 + $1.totalPips }

        let result: RoundResult

        if playerHand.isEmpty {
            // Player wins round
            let score = aiPips
            playerScore += score
            result = RoundResult(
                playerRoundScore: score,
                aiRoundScore: 0,
                winner: "player",
                reason: "You played all your tiles! (\(score) pts)"
            )
        } else if aiHand.isEmpty {
            // AI wins round
            let score = playerPips
            aiScore += score
            result = RoundResult(
                playerRoundScore: 0,
                aiRoundScore: score,
                winner: "ai",
                reason: "AI played all tiles. (\(score) pts)"
            )
        } else {
            // Blocked game — lower pip count wins
            if playerPips < aiPips {
                let score = aiPips - playerPips
                playerScore += score
                result = RoundResult(
                    playerRoundScore: score,
                    aiRoundScore: 0,
                    winner: "player",
                    reason: "Game blocked. You had fewer pips! (\(score) pts)"
                )
            } else if aiPips < playerPips {
                let score = playerPips - aiPips
                aiScore += score
                result = RoundResult(
                    playerRoundScore: 0,
                    aiRoundScore: score,
                    winner: "ai",
                    reason: "Game blocked. AI had fewer pips. (\(score) pts)"
                )
            } else {
                result = RoundResult(
                    playerRoundScore: 0,
                    aiRoundScore: 0,
                    winner: "blocked",
                    reason: "Game blocked with equal pips. No score!"
                )
            }
        }

        roundResult = result
        checkMatchOver()
    }

    private func checkMatchOver() {
        if playerScore >= matchPointTarget || aiScore >= matchPointTarget {
            phase = .matchOver
        }
    }
}
