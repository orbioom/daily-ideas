import SwiftUI
import SwiftData

/// Create a new prayer or edit an existing one. When `prayer` is nil we insert
/// a new record on save; otherwise we update the passed model in place.
struct PrayerEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var prayer: Prayer?

    @State private var title = ""
    @State private var body_ = ""
    @State private var category: PrayerCategory = .petition
    @State private var personName = ""
    @State private var isPinned = false

    private var isEditing: Bool { prayer != nil }
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Prayer") {
                    TextField("Title", text: $title)
                    TextField("What's on your heart? (optional)", text: $body_, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(PrayerCategory.allCases) { cat in
                            Label(cat.label, systemImage: cat.symbol).tag(cat)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Details") {
                    TextField("Who is this for? (optional)", text: $personName)
                    Toggle(isOn: $isPinned) {
                        Label("Pin to top", systemImage: "pin")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit Prayer" : "New Prayer")
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
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let prayer else { return }
        title = prayer.title
        body_ = prayer.body
        category = prayer.category
        personName = prayer.personName
        isPinned = prayer.isPinned
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let trimmedBody = body_.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPerson = personName.trimmingCharacters(in: .whitespacesAndNewlines)

        if let prayer {
            prayer.title = trimmedTitle
            prayer.body = trimmedBody
            prayer.category = category
            prayer.personName = trimmedPerson
            prayer.isPinned = isPinned
        } else {
            let new = Prayer(title: trimmedTitle, body: trimmedBody, category: category,
                             personName: trimmedPerson, isPinned: isPinned)
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
