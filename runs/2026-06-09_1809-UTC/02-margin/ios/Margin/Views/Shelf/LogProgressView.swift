import SwiftUI
import SwiftData

/// A sheet to log reading progress on a book. Honors the user's preferred
/// progress unit (pages vs percent) for the input, records a `ReadingSession`,
/// and auto-advances status to reading / finished as appropriate.
struct LogProgressView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("margin.progressUnit") private var progressUnit = ProgressUnit.pages.rawValue

    @Bindable var book: Book

    @State private var newPage: Double
    @State private var minutes: String = ""
    @State private var note: String = ""

    private var unit: ProgressUnit { ProgressUnit(rawValue: progressUnit) ?? .pages }

    init(book: Book) {
        self.book = book
        _newPage = State(initialValue: Double(book.currentPage))
    }

    private var pagesDelta: Int { max(0, Int(newPage) - book.currentPage) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        BookSpine(book: book, width: 38, height: 54)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(book.title).font(.headline).foregroundStyle(Brand.text).lineLimit(2)
                            Text(book.author).font(.subheadline).foregroundStyle(Brand.text2).lineLimit(1)
                        }
                    }
                }

                Section("Progress") {
                    if unit == .pages {
                        HStack {
                            Text("On page")
                            Spacer()
                            Text("\(Int(newPage)) of \(book.totalPages)")
                                .foregroundStyle(Brand.text2)
                                .font(Brand.mono(15))
                        }
                        Slider(value: $newPage, in: 0...Double(book.totalPages), step: 1)
                            .accessibilityLabel("Current page")
                            .accessibilityValue("\(Int(newPage)) of \(book.totalPages)")
                    } else {
                        let pct = book.totalPages > 0 ? Double(Int(newPage)) / Double(book.totalPages) : 0
                        HStack {
                            Text("Progress")
                            Spacer()
                            Text(Format.percent(pct))
                                .foregroundStyle(Brand.text2)
                                .font(Brand.mono(15))
                        }
                        Slider(value: $newPage, in: 0...Double(book.totalPages), step: 1)
                            .accessibilityLabel("Reading progress")
                            .accessibilityValue(Format.percent(pct))
                    }
                    if pagesDelta > 0 {
                        Text("That's \(pagesDelta) new page\(pagesDelta == 1 ? "" : "s") this session.")
                            .font(.footnote)
                            .foregroundStyle(Brand.text3)
                    }
                }

                Section("Session (optional)") {
                    HStack {
                        Text("Minutes")
                        Spacer()
                        TextField("0", text: $minutes)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .accessibilityLabel("Minutes read")
                    }
                    TextField("Note", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Log progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let target = min(max(Int(newPage), 0), book.totalPages)
        let delta = max(0, target - book.currentPage)

        // Record a session if any pages or minutes were logged.
        let mins = Int(minutes) ?? 0
        if delta > 0 || mins > 0 {
            let session = ReadingSession(date: .now, pagesRead: delta, minutes: mins, note: note)
            session.book = book
            context.insert(session)
        }

        book.currentPage = target

        // Auto-advance status.
        if book.status == .wantToRead && target > 0 {
            book.status = .reading
            if book.startedAt == nil { book.startedAt = .now }
        }
        if target >= book.totalPages {
            book.status = .finished
            book.currentPage = book.totalPages
            if book.finishedAt == nil { book.finishedAt = .now }
            if book.startedAt == nil { book.startedAt = .now }
        }

        try? context.save()
        Haptics.success()
        dismiss()
    }
}
