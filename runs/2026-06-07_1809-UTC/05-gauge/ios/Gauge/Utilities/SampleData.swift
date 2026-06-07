import Foundation
import SwiftData

/// Seeds a small, realistic starter library so a first launch has something to
/// explore. Only inserts when the store is empty.
enum SampleData {

    /// Inserts three sample instruments if none exist yet.
    static func seedIfEmpty(_ context: ModelContext) {
        let descriptor = FetchDescriptor<Instrument>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }
        seed(context)
    }

    /// Inserts the three sample instruments unconditionally.
    static func seed(_ context: ModelContext) {
        for instrument in makeSamples() { context.insert(instrument) }
        try? context.save()
    }

    /// Builds the sample instruments (kept separate so previews can reuse them).
    static func makeSamples() -> [Instrument] {
        // Strat-style electric, 25.5", .010–.046 nickel wound, standard E.
        let strat = Instrument(name: "Strat-style Electric",
                               type: .electricGuitar,
                               scaleLengthIn: 25.5,
                               notes: "Standard E tuning, regular .010s.")
        strat.strings = electricSet(on: strat,
                                    gauges: [(10, .plainSteel), (13, .plainSteel), (17, .plainSteel),
                                             (26, .nickelWound), (36, .nickelWound), (46, .nickelWound)],
                                    notes: ["E4", "B3", "G3", "D3", "A2", "E2"])

        // Les-Paul-style, 24.75", .010–.046 nickel wound, standard E.
        let lp = Instrument(name: "Les-Paul-style",
                            type: .electricGuitar,
                            scaleLengthIn: 24.75,
                            notes: "Shorter scale — slightly looser feel.")
        lp.strings = electricSet(on: lp,
                                 gauges: [(10, .plainSteel), (13, .plainSteel), (17, .plainSteel),
                                          (26, .nickelWound), (36, .nickelWound), (46, .nickelWound)],
                                 notes: ["E4", "B3", "G3", "D3", "A2", "E2"])

        // Jazz Bass 4, 34", .045–.105 nickel wound, E1 A1 D2 G2.
        let bass = Instrument(name: "Jazz Bass 4",
                              type: .bass4,
                              scaleLengthIn: 34.0,
                              notes: "Long-scale four-string, standard tuning.")
        bass.strings = electricSet(on: bass,
                                   gauges: [(45, .nickelWound), (65, .nickelWound),
                                            (85, .nickelWound), (105, .nickelWound)],
                                   notes: ["G2", "D2", "A1", "E1"])

        return [strat, lp, bass]
    }

    /// Helper building ordered StringSlots from parallel gauge/note arrays.
    private static func electricSet(on instrument: Instrument,
                                    gauges: [(Int, Material)],
                                    notes: [String]) -> [StringSlot] {
        var slots: [StringSlot] = []
        let count = min(gauges.count, notes.count)
        for index in 0..<count {
            slots.append(StringSlot(position: index + 1,
                                    noteName: notes[index],
                                    gaugeThou: gauges[index].0,
                                    material: gauges[index].1,
                                    instrument: instrument))
        }
        return slots
    }
}
