import Foundation

/// Pure text/timing analysis. No UI, no audio — fully testable.
enum SpeechAnalyzer {

    static let singleFillers: Set<String> = [
        "um", "uh", "er", "ah", "umm", "uhh", "hmm",
        "like", "basically", "actually", "literally",
    ]
    static let pairFillers: [(String, String)] = [
        ("you", "know"), ("i", "mean"), ("sort", "of"), ("kind", "of"),
    ]

    struct Analysis {
        let wordCount: Int
        let fillerCount: Int
        let fillerBreakdown: [String: Int]
        let wordsPerMinute: Double
        let vocabularyDiversity: Double
        let score: Int
    }

    static func normalizeToken(_ raw: Substring) -> String {
        raw.lowercased().trimmingCharacters(in: .punctuationCharacters)
    }

    static func tokenize(_ text: String) -> [String] {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .map(normalizeToken)
            .filter { !$0.isEmpty }
    }

    /// Counts fillers: two-word fillers first (consuming their tokens), then singles.
    static func countFillers(tokens: [String]) -> (total: Int, breakdown: [String: Int]) {
        var breakdown: [String: Int] = [:]
        var consumed = [Bool](repeating: false, count: tokens.count)
        if tokens.count >= 2 {
            for i in 0..<(tokens.count - 1) {
                guard !consumed[i], !consumed[i + 1] else { continue }
                for (a, b) in pairFillers where tokens[i] == a && tokens[i + 1] == b {
                    breakdown["\(a) \(b)", default: 0] += 1
                    consumed[i] = true
                    consumed[i + 1] = true
                    break
                }
            }
        }
        for i in 0..<tokens.count {
            guard !consumed[i] else { continue }
            if singleFillers.contains(tokens[i]) {
                breakdown[tokens[i], default: 0] += 1
            }
        }
        return (breakdown.values.reduce(0, +), breakdown)
    }

    /// Full analysis of a finished talk.
    static func analyze(transcript: String, duration: TimeInterval,
                        targetWPMLow: Double = 120, targetWPMHigh: Double = 160) -> Analysis {
        let tokens = tokenize(transcript)
        let wordCount = tokens.count
        let minutes = max(duration / 60, 1.0 / 60)
        let wpm = Double(wordCount) / minutes
        let fillers = countFillers(tokens: tokens)
        let diversity = wordCount > 0 ? Double(Set(tokens).count) / Double(wordCount) : 0

        // Score: start at 100.
        // - Fillers: −4 per filler-per-minute, capped at −40.
        // - Pace: −0.5 per WPM outside the target band, capped at −30.
        // - Vocabulary: up to −15 as diversity falls below 0.45.
        // - Substance: heavy penalty for sessions under 15 words.
        var score = 100.0
        let fpm = Double(fillers.total) / minutes
        score -= min(fpm * 4, 40)
        let paceMiss: Double
        if wpm < targetWPMLow { paceMiss = targetWPMLow - wpm }
        else if wpm > targetWPMHigh { paceMiss = wpm - targetWPMHigh }
        else { paceMiss = 0 }
        score -= min(paceMiss * 0.5, 30)
        if diversity < 0.45 && wordCount >= 20 {
            score -= min((0.45 - diversity) * 100, 15)
        }
        if wordCount < 15 { score = min(score, 25) }
        let final = max(0, min(100, Int(score.rounded())))

        return Analysis(wordCount: wordCount, fillerCount: fillers.total,
                        fillerBreakdown: fillers.breakdown,
                        wordsPerMinute: wpm, vocabularyDiversity: diversity,
                        score: final)
    }

    static func grade(forScore score: Int) -> (label: String, detail: String) {
        switch score {
        case 85...: return ("Polished", "Conference-stage delivery. Keep this pace.")
        case 70..<85: return ("Strong", "Clear and controlled, with a little to trim.")
        case 50..<70: return ("Developing", "The bones are good — work the drills.")
        case 30..<50: return ("Rough", "Lots of fillers or pace trouble. Very fixable.")
        default: return ("Just starting", "Every great speaker started here. Go again.")
        }
    }

    static func paceLabel(wpm: Double, low: Double = 120, high: Double = 160) -> String {
        if wpm <= 0 { return "—" }
        if wpm < low { return "Slow" }
        if wpm > high { return "Rushing" }
        return "On pace"
    }

    /// Word ranges of fillers in the original text, for transcript highlighting.
    static func fillerRanges(in text: String) -> [Range<String.Index>] {
        var words: [(range: Range<String.Index>, token: String)] = []
        text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .byWords) { sub, range, _, _ in
            if let sub {
                words.append((range, sub.lowercased()))
            }
        }
        var ranges: [Range<String.Index>] = []
        var consumed = [Bool](repeating: false, count: words.count)
        if words.count >= 2 {
            for i in 0..<(words.count - 1) {
                guard !consumed[i], !consumed[i + 1] else { continue }
                for (a, b) in pairFillers where words[i].token == a && words[i + 1].token == b {
                    ranges.append(words[i].range.lowerBound..<words[i + 1].range.upperBound)
                    consumed[i] = true
                    consumed[i + 1] = true
                    break
                }
            }
        }
        for i in 0..<words.count where !consumed[i] && singleFillers.contains(words[i].token) {
            ranges.append(words[i].range)
        }
        return ranges
    }

    static func formatDuration(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded())
        let m = total / 60, s = total % 60
        return m > 0 ? String(format: "%d:%02d", m, s) : "\(s)s"
    }
}
