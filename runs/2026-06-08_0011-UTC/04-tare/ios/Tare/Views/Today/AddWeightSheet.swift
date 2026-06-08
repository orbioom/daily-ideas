import SwiftUI
import SwiftData

struct AddWeightSheet: View {
    var existing: WeightEntry?
    var defaultKg: Double?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("tare.unit") private var unitRaw = WeightUnit.kg.rawValue

    @State private var amount = 70.0
    @State private var date = Date()
    @State private var note = ""

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }
    private var step: Double { unit == .kg ? 0.1 : 0.2 }
    private var range: ClosedRange<Double> { unit == .kg ? 20...400 : 44...880 }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 22) {
                        VStack(spacing: 6) {
                            Text(String(format: "%.1f", amount))
                                .font(Brand.mono(56, weight: .semibold))
                                .foregroundStyle(Brand.text)
                                .contentTransition(.numericText())
                            Text(unit == .kg ? "kilograms" : "pounds")
                                .font(.subheadline).foregroundStyle(Brand.text2)
                        }
                        .padding(.top, 12)

                        HStack(spacing: 14) {
                            adjustButton("-1", -1)
                            adjustButton("-0.1", -step)
                            adjustButton("+0.1", step)
                            adjustButton("+1", 1)
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Slider(value: $amount, in: range, step: step)
                                    .tint(Brand.info)
                                    .accessibilityLabel("Weight")
                                    .accessibilityValue(String(format: "%.1f", amount))
                                Divider().overlay(Brand.hairline)
                                DatePicker("When", selection: $date, in: ...Date())
                                    .foregroundStyle(Brand.text)
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Eyebrow(text: "NOTE")
                                TextField("Optional (e.g. post-workout)", text: $note, axis: .vertical)
                                    .lineLimit(1...3).foregroundStyle(Brand.text)
                            }
                        }

                        Button("Save weigh-in") { save() }
                            .buttonStyle(InkButtonStyle())
                    }
                    .padding(20)
                }
            }
            .navigationTitle(existing == nil ? "New weigh-in" : "Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .onAppear(perform: load)
        }
    }

    private func adjustButton(_ label: String, _ delta: Double) -> some View {
        Button {
            amount = min(range.upperBound, max(range.lowerBound, (amount + delta).rounded(toPlaces: 1)))
            Haptics.selection()
        } label: {
            Text(label).font(Brand.mono(14, weight: .medium))
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(Brand.text)
        }
        .buttonStyle(.plain)
    }

    private func load() {
        if let e = existing {
            amount = Units.fromKg(e.kilograms, to: unit).rounded(toPlaces: 1)
            date = e.date; note = e.note
        } else if let kg = defaultKg {
            amount = Units.fromKg(kg, to: unit).rounded(toPlaces: 1)
        }
    }

    private func save() {
        let kg = Units.toKg(amount, from: unit)
        if let e = existing {
            e.kilograms = kg; e.date = date; e.note = note
        } else {
            context.insert(WeightEntry(date: date, kilograms: kg, note: note))
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
