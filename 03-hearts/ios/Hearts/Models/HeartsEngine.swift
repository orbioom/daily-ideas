import Foundation

enum HeartsPhase {
    case passing, playing, roundEnd, gameOver
}

enum PassDirection: Int {
    case left = 0, right, across, hold

    var label: String {
        switch self { case .left: return "Left"; case .right: return "Right"; case .across: return "Across"; case .hold: return "Hold (no pass)" }
    }
}

enum AILevel: String, CaseIterable, Identifiable {
    case easy = "Easy", medium = "Medium", hard = "Hard"
    var id: String { rawValue }
}

struct TrickCard: Identifiable {
    let id = UUID()
    let card: Card
    let playerIndex: Int
}

struct CompletedRound: Identifiable {
    let id = UUID()
    let scores: [Int]
    let shooterIndex: Int?
}

@Observable
final class HeartsEngine {
    let aiLevel: AILevel

    var playerNames: [String] = ["You", "West", "North", "East"]
    var hands: [[Card]] = [[], [], [], []]
    var phase: HeartsPhase = .passing
    var passDirection: PassDirection = .left
    var selectedToPass: Set<Card> = []

    var currentTrick: [TrickCard] = []
    var leadPlayerIndex: Int = 0
    var currentPlayerIndex: Int = 0
    var heartsBroken: Bool = false
    var firstTrick: Bool = true

    var roundScores: [Int] = [0, 0, 0, 0]
    var totalScores: [Int] = [0, 0, 0, 0]
    var completedRounds: [CompletedRound] = []
    var winThreshold: Int = 100

    var lastCompletedTrick: [TrickCard] = []
    var lastTrickWinner: Int = 0
    var showTrickResult: Bool = false

    var gameWinnerIndex: Int? = nil

    init(aiLevel: AILevel = .medium) {
        self.aiLevel = aiLevel
        dealCards()
    }

    func dealCards() {
        var deck = Card.fullDeck.shuffled()
        hands = (0..<4).map { i in Array(deck[(i * 13)..<((i + 1) * 13)]).sorted { a, b in
            a.suit == b.suit ? a.rank < b.rank : a.suit < b.suit
        }}
        roundScores = [0, 0, 0, 0]
        heartsBroken = false
        firstTrick = true
        currentTrick = []
        selectedToPass = []
        phase = passDirection == .hold ? .playing : .passing

        if phase == .playing {
            startPlay()
        }
    }

    func startPlay() {
        let twoOfClubs = Card.twoOfClubs
        for (i, hand) in hands.enumerated() {
            if hand.contains(twoOfClubs) {
                leadPlayerIndex = i
                currentPlayerIndex = i
                break
            }
        }
        aiPlayIfNeeded()
    }

    // MARK: - Passing

    func togglePass(_ card: Card) {
        if selectedToPass.contains(card) {
            selectedToPass.remove(card)
        } else if selectedToPass.count < 3 {
            selectedToPass.insert(card)
        }
    }

    func confirmPass() {
        guard selectedToPass.count == 3, phase == .passing else { return }
        let passCards = Array(selectedToPass)
        let receiverIdx = receiverIndex(for: 0, direction: passDirection)

        var aiPasses: [[Card]] = [passCards, [], [], []]
        for i in 1..<4 {
            aiPasses[i] = aiChoosePassCards(playerIndex: i)
        }

        for sender in 0..<4 {
            let receiver = receiverIndex(for: sender, direction: passDirection)
            for card in aiPasses[sender] {
                hands[sender].removeAll { $0 == card }
                hands[receiver].append(card)
            }
        }

        for i in 0..<4 {
            hands[i].sort { a, b in a.suit == b.suit ? a.rank < b.rank : a.suit < b.suit }
        }

        selectedToPass = []
        phase = .playing
        startPlay()
    }

    private func receiverIndex(for sender: Int, direction: PassDirection) -> Int {
        switch direction {
        case .left:   return (sender + 1) % 4
        case .right:  return (sender + 3) % 4
        case .across: return (sender + 2) % 4
        case .hold:   return sender
        }
    }

    private func aiChoosePassCards(playerIndex: Int) -> [Card] {
        var hand = hands[playerIndex]
        switch aiLevel {
        case .easy:
            return Array(hand.shuffled().prefix(3))
        case .medium:
            var picks: [Card] = []
            if let qos = hand.first(where: { $0.isQueenOfSpades }) { picks.append(qos) }
            if let ks = hand.first(where: { $0.suit == .spades && $0.rank == .king }) { picks.append(ks) }
            if let as_ = hand.first(where: { $0.suit == .spades && $0.rank == .ace }) { picks.append(as_) }
            let hearts = hand.filter(\.isHeart).sorted { $0.rank > $1.rank }
            for h in hearts where picks.count < 3 { picks.append(h) }
            let high = hand.filter { !$0.isHeart && !$0.isQueenOfSpades }.sorted { $0.rank > $1.rank }
            for h in high where picks.count < 3 { picks.append(h) }
            return Array(picks.prefix(3))
        case .hard:
            var picks: [Card] = []
            let spades = hand.filter { $0.suit == .spades }.sorted { $0.rank > $1.rank }
            for s in spades where picks.count < 3 { picks.append(s) }
            let hearts = hand.filter(\.isHeart).sorted { $0.rank > $1.rank }
            for h in hearts where picks.count < 3 { picks.append(h) }
            return Array(picks.prefix(3))
        }
    }

    // MARK: - Playing

    func playCard(_ card: Card, playerIndex: Int = 0) {
        guard phase == .playing, currentPlayerIndex == playerIndex else { return }
        guard legalCards(for: playerIndex).contains(card) else { return }

        hands[playerIndex].removeAll { $0 == card }
        currentTrick.append(TrickCard(card: card, playerIndex: playerIndex))

        if card.isHeart { heartsBroken = true }

        if currentTrick.count == 4 {
            resolveTrick()
        } else {
            currentPlayerIndex = (currentPlayerIndex + 1) % 4
            aiPlayIfNeeded()
        }
    }

    private func resolveTrick() {
        guard let lead = currentTrick.first else { return }
        let leadSuit = lead.card.suit
        let winner = currentTrick.max { a, b in
            guard a.card.suit == leadSuit, b.card.suit == leadSuit else {
                return a.card.suit != leadSuit
            }
            return a.card.rank < b.card.rank
        }!
        let winnerIdx = winner.playerIndex
        let points = currentTrick.reduce(0) { $0 + $1.card.pointValue }
        roundScores[winnerIdx] += points

        lastCompletedTrick = currentTrick
        lastTrickWinner = winnerIdx
        showTrickResult = true

        currentTrick = []
        firstTrick = false
        leadPlayerIndex = winnerIdx
        currentPlayerIndex = winnerIdx

        if hands.allSatisfy(\.isEmpty) {
            finishRound()
        }
    }

    func dismissTrickResult() {
        showTrickResult = false
        if !hands.allSatisfy(\.isEmpty) {
            aiPlayIfNeeded()
        }
    }

    func legalCards(for playerIndex: Int) -> [Card] {
        let hand = hands[playerIndex]
        guard !hand.isEmpty else { return [] }

        if currentTrick.isEmpty {
            if firstTrick { return [Card.twoOfClubs] }
            if !heartsBroken {
                let nonHearts = hand.filter { !$0.isHeart }
                return nonHearts.isEmpty ? hand : nonHearts
            }
            return hand
        }

        let leadSuit = currentTrick.first!.card.suit
        let suited = hand.filter { $0.suit == leadSuit }

        if !suited.isEmpty { return suited }

        if firstTrick {
            let safe = hand.filter { !$0.isHeart && !$0.isQueenOfSpades }
            return safe.isEmpty ? hand : safe
        }

        return hand
    }

    private func aiPlayIfNeeded() {
        guard phase == .playing else { return }
        guard currentPlayerIndex != 0 else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self, self.phase == .playing, self.currentPlayerIndex != 0 else { return }
            let idx = self.currentPlayerIndex
            let legal = self.legalCards(for: idx)
            guard !legal.isEmpty else { return }
            let chosen = self.aiChooseCard(playerIndex: idx, legal: legal)
            self.playCard(chosen, playerIndex: idx)
        }
    }

    private func aiChooseCard(playerIndex: Int, legal: [Card]) -> Card {
        switch aiLevel {
        case .easy:
            return legal.randomElement()!
        case .medium:
            if let low = legal.filter({ $0.pointValue == 0 }).sorted(by: { $0.rank < $1.rank }).first {
                return low
            }
            return legal.sorted { $0.rank < $1.rank }.first!
        case .hard:
            let leadSuit = currentTrick.first?.card.suit
            if let ls = leadSuit {
                let suited = legal.filter { $0.suit == ls }
                if !suited.isEmpty {
                    let trickHighRank = currentTrick.filter { $0.card.suit == ls }.map(\.card.rank).max()!
                    let winning = suited.filter { $0.rank > trickHighRank }
                    let losing = suited.filter { $0.rank < trickHighRank }
                    if !losing.isEmpty { return losing.max(by: { $0.rank < $1.rank })! }
                    if !winning.isEmpty { return winning.min(by: { $0.rank < $1.rank })! }
                    return suited.first!
                }
            }
            if let qos = legal.first(where: { $0.isQueenOfSpades }) { return qos }
            if let highHeart = legal.filter(\.isHeart).max(by: { $0.rank < $1.rank }) { return highHeart }
            return legal.sorted { $0.rank > $1.rank }.first!
        }
    }

    // MARK: - Round End

    private func finishRound() {
        phase = .roundEnd
        let moonShooter = (0..<4).first { roundScores[$0] == 26 }
        var roundAdjusted = roundScores
        if let shooter = moonShooter {
            for i in 0..<4 { roundAdjusted[i] = i == shooter ? 0 : 26 }
        }
        completedRounds.append(CompletedRound(scores: roundAdjusted, shooterIndex: moonShooter))
        for i in 0..<4 { totalScores[i] += roundAdjusted[i] }

        if totalScores.contains(where: { $0 >= winThreshold }) {
            gameWinnerIndex = totalScores.enumerated().min(by: { $0.element < $1.element })?.offset
            phase = .gameOver
        }
    }

    func startNextRound() {
        let next = (passDirection.rawValue + 1) % 4
        passDirection = PassDirection(rawValue: next)!
        dealCards()
    }

    func startNewGame() {
        totalScores = [0, 0, 0, 0]
        completedRounds = []
        gameWinnerIndex = nil
        passDirection = .left
        dealCards()
    }
}
