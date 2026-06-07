import SwiftUI
import SwiftData

/// A sheet for applying a factory string set or tuning preset to an instrument.
/// Each option previews the total tension it would produce on this instrument.
struct ApplyPickerSheet: View {
    enum Mode { case set, tuning }

    var instrument: Instrument
    var mode: Mode

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("gauge.unit") private var unitRaw = WeightUnit.pounds.rawValue

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .pounds }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if mode == .set {
                            ForEach(StringSets.sets) { set in
                                Button { applySet(set) } label: {
                                    setRow(set)
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            ForEach(StringSets.tunings) { tuning in
                                Button { applyTuning(tuning) } label: {
                                    tuningRow(tuning)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(mode == .set ? "Apply String Set" : "Apply Tuning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func setRow(_ set: StringSetPreset) -> some View {
        let total = previewSetTotal(set)
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
                    Text("est. total").font(Brand.mono(9)).foregroundStyle(Brand.text3)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(set.name), \(set.detail), estimated total \(unit.format(fromLb: total))")
    }

    private func tuningRow(_ tuning: TuningPreset) -> some View {
        GlassCard(padding: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tuning.name).font(.headline).foregroundStyle(Brand.text)
                    Text(tuning.detail).font(.caption).foregroundStyle(Brand.text2)
                    Text(tuning.notesLabel)
                        .font(Brand.mono(12))
                        .foregroundStyle(Brand.text3)
                }
                Spacer()
                Badge(text: "\(tuning.stringCount) str", color: Brand.info)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tuning.name), \(tuning.notesLabel)")
    }

    /// Estimates the total tension a set would produce on this instrument,
    /// matching set gauges against the instrument's current notes by position.
    private func previewSetTotal(_ set: StringSetPreset) -> Double {
        let notes = instrument.orderedStrings.map { $0.noteName }
        var total = 0.0
        for (index, spec) in set.strings.enumerated() {
            let note = index < notes.count ? notes[index] : "E2"
            if let t = TensionEngine.tensionLb(scaleLengthIn: instrument.scaleLengthIn,
                                               material: spec.material,
                                               gaugeThou: spec.gauge,
                                               noteName: note), t.isFinite {
                total += t
            }
        }
        return total
    }

    private func applySet(_ set: StringSetPreset) {
        StringSets.apply(set: set, to: instrument)
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func applyTuning(_ tuning: TuningPreset) {
        StringSets.apply(tuning: tuning, to: instrument)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
