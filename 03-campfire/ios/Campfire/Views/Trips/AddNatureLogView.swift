import SwiftUI
import SwiftData

struct AddNatureLogView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let trip: CampTrip

    @State private var category: NatureCategory = .wildlife
    @State private var title = ""
    @State private var description = ""
    @State private var locationNote = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Sighting") {
                    Picker("Category", selection: $category) {
                        ForEach(NatureCategory.allCases, id: \.self) { c in
                            Label(c.rawValue, systemImage: c.icon).tag(c)
                        }
                    }
                    .accessibilityLabel("Nature category")
                    TextField("Title (e.g. Red-tailed hawk)", text: $title)
                        .accessibilityLabel("Sighting title")
                    DatePicker("When", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .accessibilityLabel("Date and time of sighting")
                }

                Section("Details") {
                    TextField("Location note (e.g. Near the east trail)", text: $locationNote)
                        .accessibilityLabel("Location note")
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                        .accessibilityLabel("Description")
                }
            }
            .navigationTitle("Log Sighting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let log = NatureLog(category: category, title: trimmed, trip: trip)
        log.description = description
        log.locationNote = locationNote
        log.date = date
        context.insert(log)
        try? context.save()
        dismiss()
    }
}
