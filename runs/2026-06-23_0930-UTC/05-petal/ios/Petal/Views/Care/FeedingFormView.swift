import SwiftUI
import SwiftData

/// Create or edit a feeding schedule entry.
struct FeedingFormView: View {
    @Bindable var pet: Pet
    @Bindable var settings: AppSettings
    let feeding: FeedingSchedule?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var food = ""
    @State private var portion = ""
    @State private var time = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now) ?? .now
    @State private var notes = ""
    @State private var isActive = true
    @State private var showValidation = false

    private var trimmedLabel: String { label.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool { !trimmedLabel.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Meal") {
                    TextField("Label (e.g. Breakfast)", text: $label)
                    TextField("Food (e.g. Salmon kibble)", text: $food)
                    TextField("Portion (e.g. 1 cup)", text: $portion)
                }
                Section("Time") {
                    DatePicker("Time of day", selection: $time, displayedComponents: .hourAndMinute)
                    Toggle("Active", isOn: $isActive)
                }
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical).lineLimit(2...4)
                }
                if showValidation && !isValid {
                    Label("Please enter a meal label.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.danger).font(.subheadline)
                }
            }
            .navigationTitle(feeding == nil ? "New Feeding" : "Edit Feeding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let f = feeding else { return }
        label = f.label
        food = f.food
        portion = f.portion
        time = f.todayTime
        notes = f.notes
        isActive = f.isActive
    }

    private var minutesFromTime: Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    private func save() {
        guard isValid else {
            withAnimation { showValidation = true }
            Haptics.notify(.error, enabled: settings.hapticsEnabled)
            return
        }
        if let f = feeding {
            f.label = trimmedLabel
            f.food = food.trimmingCharacters(in: .whitespacesAndNewlines)
            f.portion = portion.trimmingCharacters(in: .whitespacesAndNewlines)
            f.timeMinutes = minutesFromTime
            f.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            f.isActive = isActive
        } else {
            let f = FeedingSchedule(label: trimmedLabel,
                                    food: food.trimmingCharacters(in: .whitespacesAndNewlines),
                                    portion: portion.trimmingCharacters(in: .whitespacesAndNewlines),
                                    timeMinutes: minutesFromTime,
                                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                                    isActive: isActive)
            f.pet = pet
            context.insert(f)
        }
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        dismiss()
    }
}
