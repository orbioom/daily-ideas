import SwiftUI
import SwiftData

/// Create or edit a chapter. Validates a non-empty title and start ≤ end.
struct ChapterEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let chapter: Chapter?
    let nextSortOrder: Int
    let palette: Palette

    @State private var title: String
    @State private var startDate: Date
    @State private var isOngoing: Bool
    @State private var endDate: Date
    @State private var note: String
    @State private var hex: String

    init(chapter: Chapter?, nextSortOrder: Int, palette: Palette) {
        self.chapter = chapter
        self.nextSortOrder = nextSortOrder
        self.palette = palette
        _title = State(initialValue: chapter?.title ?? "")
        _startDate = State(initialValue: chapter?.startDate ?? Date())
        _isOngoing = State(initialValue: chapter?.endDate == nil)
        _endDate = State(initialValue: chapter?.endDate ?? Date())
        _note = State(initialValue: chapter?.note ?? "")
        _hex = State(initialValue: chapter?.colorHex ?? palette.hexes.first ?? "E8A84B")
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var endBeforeStart: Bool { !isOngoing && endDate < startDate }
    private var isValid: Bool { !trimmedTitle.isEmpty && !endBeforeStart }

    var body: some View {
        NavigationStack {
            Form {
                Section("Chapter") {
                    TextField("Title", text: $title)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color").font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                        ColorPickerRow(hex: $hex, palette: palette)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    DatePicker("Starts", selection: $startDate, displayedComponents: .date)
                    Toggle("Ongoing", isOn: $isOngoing.animation())
                    if !isOngoing {
                        DatePicker("Ends", selection: $endDate, displayedComponents: .date)
                    }
                } header: {
                    Text("When")
                } footer: {
                    if endBeforeStart {
                        Text("End date must be after the start date.")
                            .foregroundStyle(Theme.bad)
                    }
                }

                Section("Note (optional)") {
                    TextField("A line about this era", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                }

                if chapter != nil {
                    Section {
                        Button(role: .destructive) { deleteChapter() } label: {
                            Label("Delete chapter", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(chapter == nil ? "New Chapter" : "Edit Chapter")
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
        let resolvedEnd: Date? = isOngoing ? nil : endDate
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if let chapter {
            chapter.title = trimmedTitle
            chapter.startDate = startDate
            chapter.endDate = resolvedEnd
            chapter.colorHex = hex
            chapter.note = trimmedNote.isEmpty ? nil : trimmedNote
        } else {
            let new = Chapter(title: trimmedTitle,
                              startDate: startDate,
                              endDate: resolvedEnd,
                              colorHex: hex,
                              note: trimmedNote.isEmpty ? nil : trimmedNote,
                              sortOrder: nextSortOrder)
            context.insert(new)
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }

    private func deleteChapter() {
        if let chapter { context.delete(chapter); try? context.save() }
        Haptics.light(settings.hapticsEnabled)
        dismiss()
    }
}
