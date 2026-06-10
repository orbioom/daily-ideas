import Foundation
import SwiftData

/// A completed (or in-progress) CBT thought record — the seven-column
/// cognitive-restructuring worksheet, stored as one entity.
@Model
final class ThoughtRecord {
    var createdAt: Date
    var situation: String
    var emotionsData: Data         // encoded [EmotionRating]
    var automaticThought: String
    var distortionsData: Data      // encoded [String] of distortion ids
    var evidenceFor: String
    var evidenceAgainst: String
    var balancedThought: String
    var emotionsAfterData: Data    // encoded [EmotionRating]
    var beliefBefore: Int          // 0...100 belief in the automatic thought
    var beliefAfter: Int           // 0...100 belief after reframing

    init(createdAt: Date = .now,
         situation: String = "",
         emotions: [EmotionRating] = [],
         automaticThought: String = "",
         distortions: [String] = [],
         evidenceFor: String = "",
         evidenceAgainst: String = "",
         balancedThought: String = "",
         emotionsAfter: [EmotionRating] = [],
         beliefBefore: Int = 50,
         beliefAfter: Int = 50) {
        self.createdAt = createdAt
        self.situation = situation
        self.emotionsData = ThoughtRecord.encode(emotions)
        self.automaticThought = automaticThought
        self.distortionsData = ThoughtRecord.encode(distortions)
        self.evidenceFor = evidenceFor
        self.evidenceAgainst = evidenceAgainst
        self.balancedThought = balancedThought
        self.emotionsAfterData = ThoughtRecord.encode(emotionsAfter)
        self.beliefBefore = beliefBefore
        self.beliefAfter = beliefAfter
    }

    // MARK: Encoded accessors

    var emotions: [EmotionRating] {
        get { ThoughtRecord.decode(emotionsData) }
        set { emotionsData = ThoughtRecord.encode(newValue) }
    }

    var emotionsAfter: [EmotionRating] {
        get { ThoughtRecord.decode(emotionsAfterData) }
        set { emotionsAfterData = ThoughtRecord.encode(newValue) }
    }

    var distortionIDs: [String] {
        get { (try? JSONDecoder().decode([String].self, from: distortionsData)) ?? [] }
        set { distortionsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    static func encode(_ ratings: [EmotionRating]) -> Data {
        (try? JSONEncoder().encode(ratings)) ?? Data()
    }
    static func encode(_ strings: [String]) -> Data {
        (try? JSONEncoder().encode(strings)) ?? Data()
    }
    static func decode(_ data: Data) -> [EmotionRating] {
        (try? JSONDecoder().decode([EmotionRating].self, from: data)) ?? []
    }

    // MARK: Derived

    /// Average intensity drop across emotions present both before and after.
    var intensityDrop: Int {
        let before = emotions
        let after = emotionsAfter
        guard !before.isEmpty, !after.isEmpty else { return 0 }
        var deltas: [Int] = []
        for b in before {
            if let a = after.first(where: { $0.name == b.name }) {
                deltas.append(b.intensity - a.intensity)
            }
        }
        guard !deltas.isEmpty else { return 0 }
        return deltas.reduce(0, +) / deltas.count
    }

    var beliefDrop: Int { beliefBefore - beliefAfter }

    var isComplete: Bool {
        !situation.isEmpty && !automaticThought.isEmpty && !balancedThought.isEmpty
    }

    var topEmotion: EmotionRating? {
        emotions.max { $0.intensity < $1.intensity }
    }
}

/// A standalone quick mood check-in (not tied to a thought record).
@Model
final class MoodLog {
    var date: Date
    var score: Int        // 1...5
    var note: String

    init(date: Date = .now, score: Int, note: String = "") {
        self.date = date
        self.score = score
        self.note = note
    }

    var label: String {
        ["", "Very low", "Low", "Okay", "Good", "Great"][min(max(score, 1), 5)]
    }

    var emoji: String {
        ["", "😟", "🙁", "😐", "🙂", "😄"][min(max(score, 1), 5)]
    }
}

/// One named emotion at an intensity. Codable so several can live in a record.
struct EmotionRating: Codable, Identifiable, Hashable {
    var name: String
    var intensity: Int    // 0...100
    var id: String { name }
}
