import SwiftUI
import SwiftData

/// A sheet for adding a stargazing-journal entry (Pro feature surface).
struct LogObservationSheet: View {
    var prefilledObject: String = ""
    var locationName: String = ""

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings

    @State private var objectName: String = ""
    @State private var note: String = ""
    @State private var place: String = ""
    @State private var date: Date = .now

    private var canSave: Bool {
        !objectName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What did you see?") {
                    TextField("Object (e.g. Saturn, Orion Nebula)", text: $objectName)
                        .textInputAutocapitalization(.words)
                }
                Section("When & where") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("Location", text: $place)
                }
                Section("Notes") {
                    TextField("How was the view? Conditions, equipment…", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("New observation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                if objectName.isEmpty { objectName = prefilledObject }
                if place.isEmpty { place = locationName }
            }
        }
    }

    private func save() {
        let trimmed = objectName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let entry = ObservationLog(
            date: date,
            objectName: trimmed,
            note: note.trimmingCharacters(in: .whitespaces),
            locationName: place.trimmingCharacters(in: .whitespaces).isEmpty ? "Unknown" : place
        )
        modelContext.insert(entry)
        try? modelContext.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
