import SwiftUI
import SwiftData

/// Sheet for logging a new check-in or editing an existing one.
struct CheckInEditorSheet: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings

    /// nil = new check-in.
    let existing: CheckIn?
    let defaultWeightKg: Double

    @State private var date: Date
    @State private var weightKg: Double
    @State private var intakeText: String
    @State private var note: String

    init(existing: CheckIn?, defaultWeightKg: Double) {
        self.existing = existing
        self.defaultWeightKg = defaultWeightKg
        _date = State(initialValue: existing?.date ?? Date())
        _weightKg = State(initialValue: existing?.weightKg ?? defaultWeightKg)
        _intakeText = State(initialValue: existing?.avgDailyIntakeKcal.map { String(Int($0.rounded())) } ?? "")
        _note = State(initialValue: existing?.note ?? "")
    }

    private var intakeValue: Double? {
        let trimmed = intakeText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let v = Double(trimmed), v > 0, v < 12000 else { return nil }
        return v
    }

    private var isValid: Bool { weightKg > 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    FuelCard {
                        VStack(alignment: .leading, spacing: 16) {
                            DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                                .tint(FuelTheme.orange)

                            Divider().overlay(FuelTheme.hairline(scheme))

                            WeightRow(title: "Weight", weightKg: $weightKg, unit: settings.weightUnit)

                            Divider().overlay(FuelTheme.hairline(scheme))

                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Avg daily intake")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(FuelTheme.primaryText(scheme))
                                    Text("Optional — sharpens TDEE estimate")
                                        .font(.caption2)
                                        .foregroundStyle(FuelTheme.secondaryText(scheme))
                                }
                                Spacer()
                                TextField("kcal", text: $intakeText)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 90)
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(FuelTheme.subtleSurface(scheme)))
                            }
                        }
                    }

                    FuelCard {
                        VStack(alignment: .leading, spacing: 8) {
                            FuelSectionHeader(title: "Note", systemImage: "text.alignleft")
                            TextField("How are you feeling? (optional)", text: $note, axis: .vertical)
                                .lineLimit(2...4)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(FuelTheme.subtleSurface(scheme)))
                        }
                    }
                }
                .padding(16)
            }
            .fuelScreenBackground(scheme)
            .navigationTitle(existing == nil ? "New check-in" : "Edit check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        guard isValid else { return }
        if let existing {
            existing.date = date
            existing.weightKg = weightKg
            existing.avgDailyIntakeKcal = intakeValue
            existing.note = note
        } else {
            let c = CheckIn(date: date, weightKg: weightKg, avgDailyIntakeKcal: intakeValue, note: note)
            modelContext.insert(c)
        }
        try? modelContext.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
