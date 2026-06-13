import Foundation
import SwiftData

/// Drives one study round against a passage: it tokenizes the text, computes the
/// masked / first-letter rendering for the current level, tracks per-word reveals,
/// and on completion updates the passage's mastery and appends a ReviewLog.
@Observable
final class StudyViewModel {
    enum Phase { case studying, grading, done }

    let passage: Passage
    let level: StudyLevel
    let tokens: [Token]
    /// Word-token ids hidden for this round (blank levels) — stable per round.
    let hiddenIDs: Set<Int>

    /// Word-token ids the learner has tapped to reveal.
    var revealed: Set<Int> = []
    var revealAll = false
    var phase: Phase = .studying

    private let seed: UInt64

    init(passage: Passage) {
        self.passage = passage
        let lvl = passage.currentMaskLevel
        self.level = lvl
        self.tokens = MaskEngine.tokenize(passage.fullText)
        // A stable seed per passage + level so blanks don't reshuffle mid-round.
        let seed = UInt64(bitPattern: Int64(passage.title.hashValue ^ (lvl.rawValue << 8)))
        self.seed = seed
        switch lvl {
        case .blanks25, .blanks50, .blanks75:
            self.hiddenIDs = MaskEngine.maskedWordIDs(passage.fullText,
                                                      fraction: lvl.blankFraction,
                                                      seed: seed)
        default:
            self.hiddenIDs = []
        }
    }

    /// Whether a given word token should be shown obscured right now.
    func isObscured(_ token: Token) -> Bool {
        guard token.isWord, !token.core.isEmpty else { return false }
        if revealAll || revealed.contains(token.id) { return false }
        switch level {
        case .read:         return false
        case .firstLetters: return true        // shown as first-letter form
        case .recall:       return true        // shown fully blanked
        default:            return hiddenIDs.contains(token.id)
        }
    }

    /// The display text for a word token in its current (possibly obscured) form.
    func display(_ token: Token) -> String {
        guard isObscured(token) else { return token.text }
        switch level {
        case .firstLetters:
            let first = token.core.first.map(String.init) ?? ""
            let blanks = String(repeating: "_", count: max(0, token.core.count - 1))
            return token.leading + first + blanks + token.trailing
        default:
            return token.leading + MaskEngine.blank(for: token.core) + token.trailing
        }
    }

    /// Whether tapping a word can reveal it (only obscured words are tappable).
    func isTappable(_ token: Token) -> Bool {
        token.isWord && !token.core.isEmpty && isObscured(token)
    }

    func reveal(_ token: Token) {
        guard isTappable(token) else { return }
        revealed.insert(token.id)
        if UserDefaults.standard.object(forKey: "revealHaptics") as? Bool ?? true {
            Haptics.soft()
        }
    }

    func peekAll() {
        revealAll = true
        Haptics.tap()
    }

    var totalHiddenCount: Int {
        switch level {
        case .read:         return 0
        case .firstLetters, .recall:
            return tokens.filter { $0.isWord && !$0.core.isEmpty }.count
        default:
            return hiddenIDs.count
        }
    }

    var revealedCount: Int {
        if revealAll { return totalHiddenCount }
        return revealed.count
    }

    /// 0...1 progress through the obscured words.
    var revealProgress: Double {
        guard totalHiddenCount > 0 else { return 1 }
        return min(1, Double(revealedCount) / Double(totalHiddenCount))
    }

    func beginGrading() {
        phase = .grading
        Haptics.tap()
    }

    /// Apply the learner's self-grade: update mastery, append a log, save.
    func grade(_ grade: SpacedRepetition.Grade, context: ModelContext) {
        let newLevel = SpacedRepetition.updatedMastery(passage.masteryLevel, grade: grade)
        passage.masteryLevel = newLevel
        passage.lastReviewed = .now

        // Setting `passage` establishes the relationship; SwiftData maintains
        // the inverse `passage.reviews` automatically, so we don't append by hand.
        let log = ReviewLog(levelIndex: level.rawValue,
                            score: SpacedRepetition.score(for: grade),
                            passage: passage)
        context.insert(log)
        try? context.save()

        if grade == .struggled { Haptics.warning() } else { Haptics.success() }
        phase = .done
    }
}
