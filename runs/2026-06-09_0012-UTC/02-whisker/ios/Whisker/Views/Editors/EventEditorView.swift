import SwiftUI
import SwiftData

struct EventEditorView: View {
    let pet: Pet
    var event: HealthEvent?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var kind: EventKind = .vetVisit
    @State private var title = ""
    @State private var detail = ""
    @State private var date = Date()
    @State private var loaded = false

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    Picker("Type", selection: $kind) {
                        ForEach(EventKind.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                    .onChange(of: kind) { _, new in
                        if title.isEmpty { title = new.title }
                    }
                    TextField("Title", text: $title)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section("Details") {
                    TextField("Notes (optional)", text: $detail, axis: .vertical).lineLimit(2...6)
                }
                if let event {
                    Section {
                        Button(role: .destructive) {
                            context.delete(event); try? context.save(); dismiss()
                        } label: { Text("Delete event") }
                    }
                }
            }
            .navigationTitle(event == nil ? "New event" : "Edit event")
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
        if let event {
            kind = event.kind; title = event.title; detail = event.detail; date = event.date
        } else {
            title = kind.title
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        if let event {
            event.kind = kind; event.title = trimmed; event.detail = detail; event.date = date
        } else {
            let new = HealthEvent(date: date, kind: kind, title: trimmed, detail: detail)
            new.pet = pet
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
