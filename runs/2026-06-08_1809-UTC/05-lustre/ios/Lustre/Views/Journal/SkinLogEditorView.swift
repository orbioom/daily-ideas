import SwiftUI
import SwiftData

struct SkinLogEditorView: View {
    var editing: SkinLog?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var rating = 3
    @State private var date = Date()
    @State private var selected: Set<SkinConcern> = []
    @State private var note = ""

    private var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("How does your skin feel?") {
                    HStack {
                        ForEach(1...5, id: \.self) { i in
                            Button {
                                rating = i; Haptics.selection()
                            } label: {
                                Image(systemName: i <= rating ? "circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(i <= rating ? Color(hex: 0x9E7BA8) : Brand.text3)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(i) of 5")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    Text(ratingLabel).font(.caption).foregroundStyle(Brand.text2)
                        .frame(maxWidth: .infinity)
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                }
                Section("Anything to note?") {
                    ForEach(SkinConcern.allCases) { c in
                        Button {
                            if selected.contains(c) { selected.remove(c) } else { selected.insert(c) }
                            Haptics.tap()
                        } label: {
                            HStack {
                                Image(systemName: c.icon).foregroundStyle(Color(hex: 0x9E7BA8)).frame(width: 24)
                                Text(c.title).foregroundStyle(Brand.text)
                                Spacer()
                                if selected.contains(c) {
                                    Image(systemName: "checkmark").foregroundStyle(Color(hex: 0x9E7BA8))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                Section("Note") {
                    TextField("Optional note", text: $note, axis: .vertical).lineLimit(2...4)
                }
                if let editing {
                    Section {
                        Button(role: .destructive) {
                            context.delete(editing); try? context.save(); Haptics.warning(); dismiss()
                        } label: { Label("Delete check-in", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Check-in" : "Skin Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear(perform: load)
        }
    }

    private var ratingLabel: String {
        switch rating {
        case 1: return "Struggling"
        case 2: return "Not great"
        case 3: return "Okay"
        case 4: return "Good"
        default: return "Glowing"
        }
    }

    private func load() {
        if let editing {
            rating = editing.rating
            date = editing.date
            selected = Set(editing.concerns)
            note = editing.note
        }
    }

    private func save() {
        let concerns = SkinConcern.allCases.filter { selected.contains($0) }
        if let editing {
            editing.rating = rating
            editing.date = date
            editing.concerns = concerns
            editing.note = note
        } else {
            context.insert(SkinLog(date: date, rating: rating, concerns: concerns, note: note))
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
