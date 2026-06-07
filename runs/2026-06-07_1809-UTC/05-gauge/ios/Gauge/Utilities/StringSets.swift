import Foundation

/// A factory string set: an ordered list of (gauge, material) pairs from the
/// thinnest/highest string (position 1) downward. Applying a set rewrites an
/// instrument's `StringSlot` gauges and materials while preserving the existing
/// notes where it can (so a re-gauge keeps the tuning).
struct StringSetPreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let detail: String
    /// (gaugeThou, material), position 1 first.
    let strings: [(gauge: Int, material: Material)]

    static func == (lhs: StringSetPreset, rhs: StringSetPreset) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var gaugeRangeLabel: String {
        guard let first = strings.first, let last = strings.last else { return "" }
        return String(format: ".%03d–.%03d", first.gauge, last.gauge)
    }
}

/// A tuning preset: notes from the thinnest/highest string (position 1) down.
struct TuningPreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let detail: String
    /// Note names, position 1 first (e.g. ["E4","B3","G3","D3","A2","E2"]).
    let notes: [String]

    static func == (lhs: TuningPreset, rhs: TuningPreset) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var stringCount: Int { notes.count }
    var notesLabel: String { notes.joined(separator: " ") }
}

/// The bundled catalogs of factory string sets and tuning presets.
enum StringSets {

    // MARK: - String sets

    static let sets: [StringSetPreset] = [
        StringSetPreset(
            name: "Electric Super Light",
            detail: "Nickel wound .009–.042",
            strings: [
                (9, .plainSteel), (11, .plainSteel), (16, .plainSteel),
                (24, .nickelWound), (32, .nickelWound), (42, .nickelWound)
            ]),
        StringSetPreset(
            name: "Electric Regular",
            detail: "Nickel wound .010–.046",
            strings: [
                (10, .plainSteel), (13, .plainSteel), (17, .plainSteel),
                (26, .nickelWound), (36, .nickelWound), (46, .nickelWound)
            ]),
        StringSetPreset(
            name: "Electric Medium",
            detail: "Nickel wound .011–.049",
            strings: [
                (11, .plainSteel), (14, .plainSteel), (18, .plainSteel),
                (28, .nickelWound), (38, .nickelWound), (49, .nickelWound)
            ]),
        StringSetPreset(
            name: "Drop / Heavy Bottom",
            detail: "Nickel wound .010–.052",
            strings: [
                (10, .plainSteel), (13, .plainSteel), (17, .plainSteel),
                (30, .nickelWound), (42, .nickelWound), (52, .nickelWound)
            ]),
        StringSetPreset(
            name: "Acoustic Light",
            detail: "Phosphor bronze .012–.053",
            strings: [
                (12, .plainSteel), (16, .plainSteel), (24, .phosphorBronze),
                (32, .phosphorBronze), (42, .phosphorBronze), (53, .phosphorBronze)
            ]),
        StringSetPreset(
            name: "Bass 4 Standard",
            detail: "Nickel wound .045–.105",
            strings: [
                (45, .nickelWound), (65, .nickelWound),
                (85, .nickelWound), (105, .nickelWound)
            ]),
        StringSetPreset(
            name: "Bass 5 Standard",
            detail: "Nickel wound .045–.130",
            strings: [
                (45, .nickelWound), (65, .nickelWound), (85, .nickelWound),
                (105, .nickelWound), (130, .nickelWound)
            ]),
        StringSetPreset(
            name: "Classical Normal",
            detail: "Nylon & nylon-wound trebles/basses",
            strings: [
                (28, .nylonClear), (32, .nylonClear), (40, .nylonClear),
                (29, .nylonWound), (35, .nylonWound), (43, .nylonWound)
            ]),
    ]

    // MARK: - Tunings

    static let tunings: [TuningPreset] = [
        TuningPreset(name: "Standard E", detail: "6-string guitar",
                     notes: ["E4", "B3", "G3", "D3", "A2", "E2"]),
        TuningPreset(name: "Drop D", detail: "Low string to D",
                     notes: ["E4", "B3", "G3", "D3", "A2", "D2"]),
        TuningPreset(name: "Drop C", detail: "Whole step down, drop",
                     notes: ["D4", "A3", "F3", "C3", "G2", "C2"]),
        TuningPreset(name: "DADGAD", detail: "Modal open tuning",
                     notes: ["D4", "A3", "G3", "D3", "A2", "D2"]),
        TuningPreset(name: "Half-step Down", detail: "Eb standard",
                     notes: ["Eb4", "Bb3", "Gb3", "Db3", "Ab2", "Eb2"]),
        TuningPreset(name: "Open G", detail: "D G D G B D",
                     notes: ["D4", "B3", "G3", "D3", "G2", "D2"]),
        TuningPreset(name: "Bass Standard", detail: "4-string bass",
                     notes: ["G2", "D2", "A1", "E1"]),
        TuningPreset(name: "Bass Drop D", detail: "Low string to D",
                     notes: ["G2", "D2", "A1", "D1"]),
    ]

    // MARK: - Application

    /// Rewrites an instrument's strings to match a set. Keeps existing notes by
    /// position where possible; falls back to a sensible default descending
    /// chromatic guess only when the instrument had fewer strings.
    static func apply(set: StringSetPreset, to instrument: Instrument) {
        let existing = instrument.orderedStrings
        var newSlots: [StringSlot] = []
        for (index, spec) in set.strings.enumerated() {
            let position = index + 1
            let note: String
            if index < existing.count {
                note = existing[index].noteName
            } else {
                note = "E2"
            }
            newSlots.append(StringSlot(position: position,
                                       noteName: note,
                                       gaugeThou: spec.gauge,
                                       material: spec.material,
                                       instrument: instrument))
        }
        instrument.strings = newSlots
    }

    /// Rewrites an instrument's notes to match a tuning, preserving gauges and
    /// materials by position. If the tuning has more strings than the instrument,
    /// new slots are created with a plausible default gauge.
    static func apply(tuning: TuningPreset, to instrument: Instrument) {
        let existing = instrument.orderedStrings
        var newSlots: [StringSlot] = []
        for (index, note) in tuning.notes.enumerated() {
            let position = index + 1
            if index < existing.count {
                let slot = existing[index]
                slot.position = position
                slot.noteName = note
                newSlots.append(slot)
            } else {
                newSlots.append(StringSlot(position: position,
                                           noteName: note,
                                           gaugeThou: 46,
                                           material: .nickelWound,
                                           instrument: instrument))
            }
        }
        instrument.strings = newSlots
    }
}
