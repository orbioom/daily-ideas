import SwiftUI
import SwiftData

/// Edit a single string: its note, gauge and material — with a live tension
/// preview and the option to delete the string. The note field validates and
/// shows a calm message when Gauge can't read it.
struct StringEditSheet: View {
    @Bindable var slot: StringSlot
    var instrument: Instrument

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("gauge.unit") private var unitRaw = WeightUnit.pounds.rawValue

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .pounds }

    private var noteIsValid: Bool {
        TensionEngine.frequency(for: slot.noteName) != nil
    }

    private var livePreview: Double? {
        TensionEngine.tensionLb(for: slot, scaleLengthIn: instrument.scaleLengthIn)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 16) {
                        previewCard

                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitle(text: "Note")
                                TextField("E4", text: $slot.noteName)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    .font(Brand.mono(17, weight: .medium))
                                if noteIsValid {
                                    Text("Scientific pitch, e.g. E2, A#2, Bb1.")
                                        .font(.caption)
                                        .foregroundStyle(Brand.text3)
                                } else {
                                    Label("Gauge can't read that note. Try a letter A–G, an optional # or b, and an octave.",
                                          systemImage: "exclamationmark.triangle")
                                        .font(.caption)
                                        .foregroundStyle(Brand.warn)
                                }
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    SectionTitle(text: "Gauge")
                                    Spacer()
                                    Text("\(slot.gaugeLabel)\"")
                                        .font(Brand.mono(17, weight: .semibold))
                                        .foregroundStyle(Brand.text)
                                }
                                Stepper(value: gaugeBinding, in: 6...140, step: 1) {
                                    Text("Gauge in thousandths")
                                        .font(.subheadline)
                                        .foregroundStyle(Brand.text2)
                                }
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionTitle(text: "Material")
                                Picker("Material", selection: materialBinding) {
                                    ForEach(Material.allCases) { material in
                                        Text(material.label).tag(material)
                                    }
                                }
                                .pickerStyle(.navigationLink)
                            }
                        }

                        Button(role: .destructive) {
                            deleteString()
                        } label: {
                            Label("Delete string", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Edit String")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { save() }
                }
            }
        }
    }

    private var previewCard: some View {
        GlassCard {
            VStack(spacing: 6) {
                Eyebrow(text: "Live tension")
                if let preview = livePreview, preview.isFinite {
                    Text(unit.format(fromLb: preview, decimals: 2))
                        .font(Brand.mono(34, weight: .bold))
                        .foregroundStyle(TensionEngine.comfort(tensionLb: preview,
                                                               isBass: instrument.type.isBass).color)
                    Text(TensionEngine.comfort(tensionLb: preview,
                                               isBass: instrument.type.isBass).label)
                        .font(.caption)
                        .foregroundStyle(Brand.text2)
                } else {
                    Text("—")
                        .font(Brand.mono(34, weight: .bold))
                        .foregroundStyle(Brand.danger)
                    Text("Enter a valid note to compute tension")
                        .font(.caption)
                        .foregroundStyle(Brand.text2)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }
    }

    private var gaugeBinding: Binding<Int> {
        Binding(get: { slot.gaugeThou },
                set: { slot.gaugeThou = min(max($0, 1), 200) })
    }

    private var materialBinding: Binding<Material> {
        Binding(get: { slot.material }, set: { slot.material = $0 })
    }

    private func deleteString() {
        Haptics.warning()
        instrument.strings.removeAll { $0.id == slot.id }
        context.delete(slot)
        renumber()
        try? context.save()
        dismiss()
    }

    private func save() {
        try? context.save()
        Haptics.success()
        dismiss()
    }

    /// Keeps positions contiguous from 1 after a deletion.
    private func renumber() {
        for (index, s) in instrument.orderedStrings.enumerated() {
            s.position = index + 1
        }
    }
}
