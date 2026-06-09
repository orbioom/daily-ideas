import Foundation

/// One ear-training question: an item to identify, the notes that sound it, and
/// the answer choices presented to the player.
struct Question: Identifiable {
    let id = UUID()
    let itemKey: String          // the correct item's raw identifier (e.g. "P5")
    let statKey: String          // the full ItemStat key (e.g. "interval.P5")
    let rootMidi: Int
    let midiNotes: [Int]
    let frequencies: [Double]
    let style: PlayStyle
    let answerLabel: String      // human label of the correct answer
    /// All choices for this drill: raw identifier → display label.
    let choices: [(raw: String, label: String)]
    let drillType: DrillType
}

/// Generates questions for a drill and grades answers. Selection is adaptive:
/// items the player is weak on (low accuracy) or hasn't seen recently are more
/// likely to come up, while brand-new items are prioritized.
enum EarEngine {

    /// Root candidates: a comfortable mid octave (C3…B3, MIDI 48–59).
    private static let rootCandidates = Array(48...59)

    /// Build a question for the drill, biased by the player's stats.
    static func makeQuestion(for drill: Drill, stats: [ItemStat]) -> Question? {
        let enabled = drill.enabledKeys
        guard !enabled.isEmpty else { return nil }

        let statByKey = Dictionary(stats.map { ($0.key, $0) }, uniquingKeysWith: { a, _ in a })
        let now = Date()

        // Adaptive weight per item: weaker + staler + newer = higher weight.
        func weight(for raw: String) -> Double {
            let full = ItemStat.key(type: drill.type, itemRaw: raw)
            guard let stat = statByKey[full], stat.attempts > 0 else {
                return 3.0   // unseen items get top priority
            }
            let weakness = 1.0 - stat.accuracy            // 0…1
            let hoursSince = max(0, now.timeIntervalSince(stat.lastSeen) / 3600)
            let recency = min(1.0, hoursSince / 48.0)     // staler → up to +1
            return 0.2 + weakness * 1.5 + recency * 0.8
        }

        let weights = enabled.map { weight(for: $0) }
        let chosenRaw = weightedPick(enabled, weights: weights) ?? enabled[0]

        let rootMidi: Int
        switch drill.rootMode {
        case .fixedC: rootMidi = 48           // C3
        case .random: rootMidi = rootCandidates.randomElement() ?? 48
        }

        let offsets = semitoneOffsets(type: drill.type, raw: chosenRaw)
        let midiNotes = offsets.map { rootMidi + $0 }
        let freqs = midiNotes.map { Theory.frequency(forMidi: $0) }

        let choices = answerChoices(for: drill)
        let answerLabel = label(type: drill.type, raw: chosenRaw)

        return Question(itemKey: chosenRaw,
                        statKey: ItemStat.key(type: drill.type, itemRaw: chosenRaw),
                        rootMidi: rootMidi,
                        midiNotes: midiNotes,
                        frequencies: freqs,
                        style: drill.playStyle,
                        answerLabel: answerLabel,
                        choices: choices,
                        drillType: drill.type)
    }

    /// True if the chosen answer matches the question's correct item.
    static func grade(question: Question, chosenRaw: String) -> Bool {
        chosenRaw == question.itemKey
    }

    // MARK: - Item geometry

    /// Semitone offsets from the root for an item of a given type.
    private static func semitoneOffsets(type: DrillType, raw: String) -> [Int] {
        switch type {
        case .interval:
            let st = Interval(rawValue: raw)?.semitones ?? 0
            return [0, st]
        case .chord:
            return ChordType(rawValue: raw)?.intervals ?? [0, 4, 7]
        case .scale:
            return ScaleType(rawValue: raw)?.steps ?? [0, 2, 4, 5, 7, 9, 11, 12]
        }
    }

    private static func label(type: DrillType, raw: String) -> String {
        switch type {
        case .interval: return Interval(rawValue: raw)?.label ?? raw
        case .chord: return ChordType(rawValue: raw)?.label ?? raw
        case .scale: return ScaleType(rawValue: raw)?.label ?? raw
        }
    }

    /// Ordered answer choices for the drill: all enabled items of that type, in
    /// the canonical catalog order so the grid is stable.
    static func answerChoices(for drill: Drill) -> [(raw: String, label: String)] {
        let enabled = Set(drill.enabledKeys)
        switch drill.type {
        case .interval:
            return Interval.allCases
                .filter { enabled.contains($0.rawValue) }
                .map { ($0.rawValue, $0.label) }
        case .chord:
            return ChordType.allCases
                .filter { enabled.contains($0.rawValue) }
                .map { ($0.rawValue, $0.label) }
        case .scale:
            return ScaleType.allCases
                .filter { enabled.contains($0.rawValue) }
                .map { ($0.rawValue, $0.label) }
        }
    }

    // MARK: - Weighted random

    private static func weightedPick(_ items: [String], weights: [Double]) -> String? {
        guard items.count == weights.count, !items.isEmpty else { return items.first }
        let total = weights.reduce(0, +)
        guard total > 0 else { return items.randomElement() }
        var r = Double.random(in: 0..<total)
        for (i, w) in weights.enumerated() {
            if r < w { return items[i] }
            r -= w
        }
        return items.last
    }
}
