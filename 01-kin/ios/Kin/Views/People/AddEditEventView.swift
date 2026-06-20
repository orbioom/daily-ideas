import SwiftUI
import SwiftData

struct AddEditEventView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let person: Person
    let event: LifeEvent?

    @State private var title = ""
    @State private var category: LifeEventCategory = .other
    @State private var hasDate = false
    @State private var date = Date()
    @State private var dateIsApprox = false
    @State private var location = ""
    @State private var description = ""

    var isEditing: Bool { event != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    TextField("Title (e.g. Graduated from Harvard)", text: $title)
                        .accessibilityLabel("Event title")
                    Picker("Category", selection: $category) {
                        ForEach(LifeEventCategory.allCases, id: \.self) { c in
                            Label(c.rawValue, systemImage: c.icon).tag(c)
                        }
                    }
                    .accessibilityLabel("Event category")
                }

                Section("Date") {
                    Toggle("Has Date", isOn: $hasDate)
                        .accessibilityLabel("Has a date")
                    if hasDate {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .accessibilityLabel("Event date")
                        Toggle("Approximate Date", isOn: $dateIsApprox)
                            .accessibilityLabel("Date is approximate")
                    }
                    TextField("Location", text: $location)
                        .accessibilityLabel("Location")
                }

                Section("Details") {
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                        .accessibilityLabel("Description")
                }
            }
            .navigationTitle(isEditing ? "Edit Event" : "New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { populate() }
        }
    }

    private func populate() {
        guard let e = event else { return }
        title = e.title
        category = e.category
        if let d = e.date { date = d; hasDate = true }
        dateIsApprox = e.dateIsApproximate
        location = e.location
        description = e.description
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        if let e = event {
            e.title = t
            e.category = category
            e.date = hasDate ? date : nil
            e.dateIsApproximate = dateIsApprox
            e.location = location
            e.description = description
        } else {
            let e = LifeEvent(title: t, category: category, person: person)
            e.date = hasDate ? date : nil
            e.dateIsApproximate = dateIsApprox
            e.location = location
            e.description = description
            context.insert(e)
        }
        try? context.save()
        dismiss()
    }
}
