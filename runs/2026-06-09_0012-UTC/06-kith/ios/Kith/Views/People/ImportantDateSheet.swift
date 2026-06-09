import SwiftUI
import SwiftData

struct ImportantDateSheet: View {
    let person: Person
    var date: ImportantDate?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var kind: DateKind = .birthday
    @State private var title = ""
    @State private var day = Date()
    @State private var recurs = true
    @State private var loaded = false

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Occasion") {
                    Picker("Type", selection: $kind) {
                        ForEach(DateKind.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                    .onChange(of: kind) { _, new in
                        if title.isEmpty || DateKind.allCases.map(\.title).contains(title) {
                            title = new.title
                        }
                    }
                    TextField("Title", text: $title)
                    DatePicker("Date", selection: $day, displayedComponents: .date)
                    Toggle("Repeats every year", isOn: $recurs)
                }
                if let date {
                    Section {
                        Button(role: .destructive) {
                            context.delete(date); try? context.save(); dismiss()
                        } label: { Text("Delete date") }
                    }
                }
            }
            .navigationTitle(date == nil ? "New date" : "Edit date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let date {
            kind = date.kind; title = date.title; day = date.date; recurs = date.recursAnnually
        } else {
            title = kind.title
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        if let date {
            date.kind = kind; date.title = trimmed; date.date = day; date.recursAnnually = recurs
        } else {
            let d = ImportantDate(title: trimmed, date: day, kind: kind, recursAnnually: recurs)
            d.person = person
            context.insert(d)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
