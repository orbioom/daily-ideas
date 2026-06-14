import SwiftUI
import SwiftData

/// Add or edit a single spin (date, optional 0–5 rating, note).
struct SpinEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    let record: Record
    /// nil = adding new.
    let spin: Spin?

    @State private var date = Date()
    @State private var rating = 0
    @State private var note = ""

    private var isEditing: Bool { spin != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Spin") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section("Rating (optional)") {
                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { i in
                            Button {
                                rating = (rating == i) ? 0 : i
                                Haptics.tap(settings.hapticsEnabled)
                            } label: {
                                Image(systemName: i <= rating ? "star.fill" : "star")
                                    .font(.system(size: 24)).foregroundStyle(Theme.accent)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(i) star\(i == 1 ? "" : "s")")
                            .accessibilityAddTraits(i == rating ? .isSelected : [])
                        }
                        Spacer()
                        if rating > 0 {
                            Button("Clear") { rating = 0 }
                                .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                }
                Section("Note") {
                    TextField("How did it sound? (optional)", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
                if isEditing {
                    Section {
                        Button(role: .destructive) { deleteSpin() } label: {
                            Label("Delete spin", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Spin" : "Log Spin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let spin {
            date = spin.date
            rating = spin.rating
            note = spin.note
        }
    }

    private func save() {
        if let spin {
            spin.date = date
            spin.rating = min(max(rating, 0), 5)
            spin.note = note
        } else {
            let newSpin = Spin(date: date, rating: rating, note: note)
            newSpin.record = record
            record.spins.append(newSpin)
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }

    private func deleteSpin() {
        if let spin {
            context.delete(spin)
            try? context.save()
        }
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
