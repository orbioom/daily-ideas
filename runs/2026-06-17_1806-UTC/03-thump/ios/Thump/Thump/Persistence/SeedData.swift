import Foundation
import SwiftData

/// Seeds built-in starter grooves and a demo song on first launch only.
enum SeedData {
    /// Builds a 16-step grid from a compact spec: `[voice: [step indices]]`.
    private static func grid(_ spec: [DrumVoice: [Int]], steps: Int = 16) -> StepGrid {
        var g = StepGrid(stepCount: steps)
        for (voice, hits) in spec {
            for s in hits {
                g.setActive(true, track: voice.rawValue, step: s)
            }
        }
        return g
    }

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Pattern>(predicate: #Predicate { $0.isBuiltIn == true })
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }

        let grooves = builtInPatterns()
        for p in grooves { context.insert(p) }

        // Demo song chaining a few of the seeded patterns.
        if let four = grooves.first(where: { $0.name == "Four on the Floor" }),
           let boom = grooves.first(where: { $0.name == "Boom Bap" }),
           let house = grooves.first(where: { $0.name == "House" }) {
            let song = Song(name: "Demo Set")
            context.insert(song)
            let s1 = SongSection(order: 0, patternID: four.persistentModelID, patternName: four.name, repeatCount: 4)
            let s2 = SongSection(order: 1, patternID: boom.persistentModelID, patternName: boom.name, repeatCount: 4)
            let s3 = SongSection(order: 2, patternID: house.persistentModelID, patternName: house.name, repeatCount: 2)
            s1.song = song; s2.song = song; s3.song = song
            song.sections = [s1, s2, s3]
        }

        try? context.save()
    }

    static func builtInPatterns() -> [Pattern] {
        var out: [Pattern] = []

        // Four on the Floor — house/disco straight kick.
        out.append(Pattern(
            name: "Four on the Floor", bpm: 124, swing: 0.0, kitID: "classic808",
            grid: grid([
                .kick: [0, 4, 8, 12],
                .closedHat: [2, 6, 10, 14],
                .openHat: [],
                .clap: [4, 12]
            ]),
            isBuiltIn: true
        ))

        // Boom Bap — classic hip-hop.
        out.append(Pattern(
            name: "Boom Bap", bpm: 90, swing: 0.18, kitID: "classic808",
            grid: grid([
                .kick: [0, 7, 10],
                .snare: [4, 12],
                .closedHat: [0, 2, 4, 6, 8, 10, 12, 14]
            ]),
            isBuiltIn: true
        ))

        // Trap Hat — rolling hats + sparse 808.
        out.append(Pattern(
            name: "Trap Hat", bpm: 140, swing: 0.05, kitID: "classic808",
            grid: grid([
                .kick: [0, 6, 10],
                .snare: [8],
                .closedHat: [0, 2, 3, 4, 6, 8, 10, 11, 12, 14, 15],
                .clap: [8]
            ]),
            isBuiltIn: true
        ))

        // House — pumping four-floor with off-beat hats + claps.
        out.append(Pattern(
            name: "House", bpm: 126, swing: 0.0, kitID: "classic808",
            grid: grid([
                .kick: [0, 4, 8, 12],
                .clap: [4, 12],
                .closedHat: [2, 6, 10, 14],
                .openHat: [2, 6, 10, 14]
            ]),
            isBuiltIn: true
        ))

        // Breakbeat — syncopated funk break.
        out.append(Pattern(
            name: "Breakbeat", bpm: 165, swing: 0.0, kitID: "classic808",
            grid: grid([
                .kick: [0, 6, 10],
                .snare: [4, 12, 14],
                .closedHat: [0, 2, 4, 6, 8, 10, 12, 14],
                .openHat: [7]
            ]),
            isBuiltIn: true
        ))

        // Half-Time — slow, heavy backbeat.
        out.append(Pattern(
            name: "Half-Time", bpm: 80, swing: 0.0, kitID: "classic808",
            grid: grid([
                .kick: [0, 10],
                .snare: [8],
                .closedHat: [0, 4, 8, 12],
                .tom: [14]
            ]),
            isBuiltIn: true
        ))

        return out
    }
}
