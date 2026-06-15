import Foundation
import SwiftData

/// A saved personality profile — the user's own, or a friend/family member's for comparison.
@Model
final class Profile {
    var name: String
    var createdAt: Date
    var isPrimary: Bool

    /// Cached, normalized 0–100 trait scores (so we can display without raw responses).
    var openness: Double
    var conscientiousness: Double
    var extraversion: Double
    var agreeableness: Double
    var neuroticism: Double

    /// The four-letter type code, e.g. "INFJ".
    var typeCode: String

    /// The raw Likert responses, encoded as JSON ([itemID:Int]) for completeness/audit.
    var responsesData: Data?

    init(name: String,
         createdAt: Date = .now,
         isPrimary: Bool = false,
         result: ScoredResult,
         responses: [Int: Int] = [:]) {
        self.name = name
        self.createdAt = createdAt
        self.isPrimary = isPrimary
        self.openness = result.score(for: .openness)
        self.conscientiousness = result.score(for: .conscientiousness)
        self.extraversion = result.score(for: .extraversion)
        self.agreeableness = result.score(for: .agreeableness)
        self.neuroticism = result.score(for: .neuroticism)
        self.typeCode = result.typeCode
        self.responsesData = Self.encode(responses)
    }

    // MARK: - Derived

    var cachedScores: [Trait: Double] {
        [
            .openness: openness,
            .conscientiousness: conscientiousness,
            .extraversion: extraversion,
            .agreeableness: agreeableness,
            .neuroticism: neuroticism
        ]
    }

    var scoredResult: ScoredResult {
        ScoringEngine.result(fromCached: cachedScores, typeCode: typeCode)
    }

    var responses: [Int: Int] {
        Self.decode(responsesData)
    }

    /// Refresh cached scores from a freshly computed result (used on retake).
    func apply(result: ScoredResult, responses: [Int: Int]) {
        openness = result.score(for: .openness)
        conscientiousness = result.score(for: .conscientiousness)
        extraversion = result.score(for: .extraversion)
        agreeableness = result.score(for: .agreeableness)
        neuroticism = result.score(for: .neuroticism)
        typeCode = result.typeCode
        responsesData = Self.encode(responses)
    }

    // MARK: - Codable helpers (no force-unwrap / try!)

    private static func encode(_ responses: [Int: Int]) -> Data? {
        // JSON object keys must be strings; map Int keys to strings.
        let stringKeyed = Dictionary(uniqueKeysWithValues: responses.map { (String($0.key), $0.value) })
        return try? JSONEncoder().encode(stringKeyed)
    }

    private static func decode(_ data: Data?) -> [Int: Int] {
        guard let data,
              let stringKeyed = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        var result: [Int: Int] = [:]
        for (k, v) in stringKeyed {
            if let key = Int(k) { result[key] = v }
        }
        return result
    }
}
