import SwiftUI
import SwiftData

/// The Library tab: browse factory string sets and tuning presets (with the
/// tension they'd produce at the reference scale length), plus a glossary.
struct LibraryView: View {
    enum LibraryTab: String, CaseIterable, Identifiable {
        case sets = "String Sets"
        case tunings = "Tunings"
        case glossary = "Glossary"
        var id: String { rawValue }
    }

    @AppStorage("gauge.unit") private var unitRaw = WeightUnit.pounds.rawValue
    @AppStorage("gauge.refScale") private var refScale = 25.5
    @State private var section: LibraryTab = .sets

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .pounds }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 16) {
                        Picker("Section", selection: $section) {
                            ForEach(LibraryTab.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: section) { _, _ in Haptics.selection() }

                        switch section {
                        case .sets: setsSection
                        case .tunings: tuningsSection
                        case .glossary: glossarySection
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Library")
        }
    }

    // MARK: - Sets

    private var setsSection: some View {
        VStack(spacing: 12) {
            referenceNote(detail: "Totals are computed at the reference scale length in Settings (\(String(format: "%.2f\"", refScale))) in standard tuning.")
            ForEach(StringSets.sets) { set in
                NavigationLink {
                    SetDetailView(set: set, refScale: refScale, unit: unit)
                } label: {
                    setRow(set)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func setRow(_ set: StringSetPreset) -> some View {
        let total = referenceTotal(for: set)
        return GlassCard(padding: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(set.name).font(.headline).foregroundStyle(Brand.text)
                    Text(set.detail).font(.caption).foregroundStyle(Brand.text2)
                    Badge(text: set.gaugeRangeLabel, color: Brand.info)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(unit.format(fromLb: total, decimals: 0))
                        .font(Brand.mono(14, weight: .semibold))
                        .foregroundStyle(Brand.text)
                    Text("ref. total").font(Brand.mono(9)).foregroundStyle(Brand.text3)
                }
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(set.name), \(set.detail), reference total \(unit.format(fromLb: total))")
    }

    /// Total tension of a set at the reference scale in a representative tuning.
    private func referenceTotal(for set: StringSetPreset) -> Double {
        let notes = referenceNotes(count: set.strings.count)
        var total = 0.0
        for (index, spec) in set.strings.enumerated() {
            let note = index < notes.count ? notes[index] : "E2"
            if let t = TensionEngine.tensionLb(scaleLengthIn: refScale,
                                               material: spec.material,
                                               gaugeThou: spec.gauge,
                                               noteName: note), t.isFinite {
                total += t
            }
        }
        return total
    }

    // MARK: - Tunings

    private var tuningsSection: some View {
        VStack(spacing: 12) {
            referenceNote(detail: "Note arrays from the thinnest string down. Apply a tuning to an instrument from its detail screen.")
            ForEach(StringSets.tunings) { tuning in
                GlassCard(padding: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(tuning.name).font(.headline).foregroundStyle(Brand.text)
                            Spacer()
                            Badge(text: "\(tuning.stringCount) str", color: Brand.info)
                        }
                        Text(tuning.detail).font(.caption).foregroundStyle(Brand.text2)
                        Text(tuning.notesLabel)
                            .font(Brand.mono(13))
                            .foregroundStyle(Brand.text)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(tuning.name), \(tuning.notesLabel)")
            }
        }
    }

    // MARK: - Glossary

    private var glossarySection: some View {
        VStack(spacing: 12) {
            glossaryCard(title: "Scale length",
                         body: "The vibrating length of the string from nut to bridge saddle. At a fixed pitch, a longer scale needs more tension — that's why baritones and basses feel stiffer.")
            glossaryCard(title: "Unit weight",
                         body: "A string's mass per inch (lb/in). It's the bridge between a gauge on the pack and the tension you feel. Plain steel follows a clean formula; wound strings come from a published table.")
            glossaryCard(title: "Why tension matters",
                         body: "Tension shapes feel, intonation and how hard the neck is pulled. A balanced set keeps each string's tension close so bends and chords respond evenly across the fretboard.")
            glossaryCard(title: "The equation",
                         body: "T = UW · (2 · L · f)² / 386.4, where T is pounds-force, UW is lb/in, L is scale length in inches and f is frequency in Hz.")
        }
    }

    private func glossaryCard(title: String, body: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: title)
                Text(body).font(.subheadline).foregroundStyle(Brand.text2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(body)")
    }

    private func referenceNote(detail: String) -> some View {
        Text(detail)
            .font(.caption)
            .foregroundStyle(Brand.text3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// A representative descending tuning for previewing a set's total.
    private func referenceNotes(count: Int) -> [String] {
        switch count {
        case 4: return ["G2", "D2", "A1", "E1"]            // bass
        case 5: return ["G2", "D2", "A1", "E1", "B0"]      // 5-string bass
        default: return ["E4", "B3", "G3", "D3", "A2", "E2"] // 6-string guitar
        }
    }
}

/// Detail view for a single factory set: per-string gauge, material and the
/// reference tension each would produce.
struct SetDetailView: View {
    let set: StringSetPreset
    let refScale: Double
    let unit: WeightUnit

    private var notes: [String] {
        switch set.strings.count {
        case 4: return ["G2", "D2", "A1", "E1"]
        case 5: return ["G2", "D2", "A1", "E1", "B0"]
        default: return ["E4", "B3", "G3", "D3", "A2", "E2"]
        }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 16) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Eyebrow(text: set.detail)
                            Text(set.name).font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
                            Text(String(format: "At %.2f\" reference scale", refScale))
                                .font(.caption).foregroundStyle(Brand.text3)
                        }
                    }
                    StatTile(value: unit.format(fromLb: total, decimals: 1),
                             label: "Reference total")
                    GlassCard {
                        VStack(spacing: 0) {
                            ForEach(Array(set.strings.enumerated()), id: \.offset) { index, spec in
                                let note = index < notes.count ? notes[index] : "E2"
                                let t = TensionEngine.tensionLb(scaleLengthIn: refScale,
                                                                material: spec.material,
                                                                gaugeThou: spec.gauge,
                                                                noteName: note)
                                HStack {
                                    Text("\(index + 1)")
                                        .font(Brand.mono(12, weight: .semibold))
                                        .foregroundStyle(Brand.text3).frame(width: 18)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(note).font(Brand.mono(14, weight: .medium)).foregroundStyle(Brand.text)
                                        Text(String(format: ".%03d\" · %@", spec.gauge, spec.material.shortLabel))
                                            .font(Brand.mono(11)).foregroundStyle(Brand.text2)
                                    }
                                    Spacer()
                                    Text(tensionText(t))
                                        .font(Brand.mono(14, weight: .semibold))
                                        .foregroundStyle(Brand.text)
                                }
                                .padding(.vertical, 8)
                                if index < set.strings.count - 1 {
                                    Divider().overlay(Brand.hairline)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(set.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tensionText(_ t: Double?) -> String {
        guard let t, t.isFinite else { return "—" }
        return unit.format(fromLb: t, decimals: 1)
    }

    private var total: Double {
        var sum = 0.0
        for (index, spec) in set.strings.enumerated() {
            let note = index < notes.count ? notes[index] : "E2"
            if let t = TensionEngine.tensionLb(scaleLengthIn: refScale,
                                               material: spec.material,
                                               gaugeThou: spec.gauge,
                                               noteName: note), t.isFinite {
                sum += t
            }
        }
        return sum
    }
}
