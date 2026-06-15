import SwiftUI
import SwiftData

/// Create or edit a past milestone.
struct MilestoneEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let milestone: LifeMilestone?
    let palette: Palette

    @State private var title: String
    @State private var date: Date
    @State private var symbol: String
    @State private var hex: String
    @State private var note: String

    init(milestone: LifeMilestone?, palette: Palette) {
        self.milestone = milestone
        self.palette = palette
        _title = State(initialValue: milestone?.title ?? "")
        _date = State(initialValue: milestone?.date ?? Date())
        _symbol = State(initialValue: milestone?.symbolName ?? "star.fill")
        _hex = State(initialValue: milestone?.colorHex ?? palette.hexes.first ?? "E8A84B")
        _note = State(initialValue: milestone?.note ?? "")
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool { !trimmedTitle.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Milestone") {
                    TextField("Title", text: $title)
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                }
                Section("Icon") {
                    SymbolPickerRow(symbol: $symbol)
                        .padding(.vertical, 2)
                }
                Section("Color") {
                    ColorPickerRow(hex: $hex, palette: palette)
                        .padding(.vertical, 2)
                }
                Section("Note (optional)") {
                    TextField("A line about this moment", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                }
                if milestone != nil {
                    Section {
                        Button(role: .destructive) { deleteItem() } label: {
                            Label("Delete milestone", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(milestone == nil ? "New Milestone" : "Edit Milestone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeDate = min(date, Date())
        if let milestone {
            milestone.title = trimmedTitle
            milestone.date = safeDate
            milestone.symbolName = symbol
            milestone.colorHex = hex
            milestone.note = trimmedNote.isEmpty ? nil : trimmedNote
        } else {
            let new = LifeMilestone(title: trimmedTitle,
                                    date: safeDate,
                                    symbolName: symbol,
                                    colorHex: hex,
                                    note: trimmedNote.isEmpty ? nil : trimmedNote)
            context.insert(new)
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }

    private func deleteItem() {
        if let milestone { context.delete(milestone); try? context.save() }
        Haptics.light(settings.hapticsEnabled)
        dismiss()
    }
}
