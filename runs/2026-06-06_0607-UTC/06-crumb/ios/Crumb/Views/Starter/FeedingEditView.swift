import SwiftUI
import SwiftData

/// Log a feeding: date, ratio (starter : flour : water), flour type, and a note.
/// Ratio parts are validated to be > 0 before save.
struct FeedingEditView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var starter: Starter

    @State private var date: Date = .now
    @State private var starterText: String = "1"
    @State private var flourText: String = "2"
    @State private var waterText: String = "2"
    @State private var flourType: String = ""
    @State private var notes: String = ""
    @State private var loaded = false

    private var starterParts: Double { Double(starterText) ?? 0 }
    private var flourParts: Double { Double(flourText) ?? 0 }
    private var waterParts: Double { Double(waterText) ?? 0 }

    private var canSave: Bool {
        starterParts > 0 && flourParts > 0 && waterParts > 0
    }

    private var impliedHydration: Double {
        guard flourParts > 0 else { return 0 }
        return waterParts / flourParts * 100
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    DatePicker("Fed at", selection: $date)
                }

                Section {
                    ratioField("Starter", text: $starterText, tint: Brand.roleColor(.levain))
                    ratioField("Flour", text: $flourText, tint: Brand.roleColor(.flour))
                    ratioField("Water", text: $waterText, tint: Brand.roleColor(.water))
                    HStack {
                        Text("Implied hydration")
                            .foregroundStyle(Brand.text2)
                        Spacer()
                        Text("\(BakersMath.displayPercent(impliedHydration))%")
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(canSave ? Brand.text : Brand.text3)
                            .monospacedDigit()
                    }
                } header: {
                    Text("Ratio (starter : flour : water)")
                } footer: {
                    Text("All three parts must be greater than zero.")
                }

                Section("Flour & notes") {
                    TextField("Flour type", text: $flourType)
                        .textInputAutocapitalization(.words)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Log Feeding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
        .onAppear(perform: loadIfNeeded)
    }

    @ViewBuilder
    private func ratioField(_ title: String, text: Binding<String>, tint: Color) -> some View {
        HStack {
            Circle().fill(tint).frame(width: 10, height: 10)
                .accessibilityHidden(true)
            Text(title)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(Brand.mono(16))
                .monospacedDigit()
                .frame(width: 70)
        }
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        // Default to the starter's usual flour and the previous ratio if available.
        if let last = starter.lastFeeding {
            starterText = trimNumber(last.starterParts)
            flourText = trimNumber(last.flourParts)
            waterText = trimNumber(last.waterParts)
            flourType = last.flourType
        } else {
            flourType = starter.flourType
        }
    }

    private func trimNumber(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value)) }
        return String(format: "%.1f", value)
    }

    private func save() {
        guard canSave else { return }
        let cleanFlour = flourType.trimmingCharacters(in: .whitespacesAndNewlines)
        let feeding = Feeding(date: date,
                              starterParts: starterParts,
                              flourParts: flourParts,
                              waterParts: waterParts,
                              flourType: cleanFlour.isEmpty ? starter.flourType : cleanFlour,
                              notes: notes.trimmingCharacters(in: .whitespacesAndNewlines))
        feeding.starter = starter
        context.insert(feeding)
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}
