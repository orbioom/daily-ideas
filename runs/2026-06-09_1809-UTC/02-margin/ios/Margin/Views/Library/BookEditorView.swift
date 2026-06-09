import SwiftUI
import SwiftData

/// Add or edit a book. When `existing` is nil it creates a new book; otherwise it
/// edits in place. Lets the reader pick title, author, pages, genre, format,
/// status, and tags (including creating new tags inline).
struct BookEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("margin.defaultFormat") private var defaultFormat = BookFormat.paper.rawValue

    @Query(sort: \BookTag.name) private var allTags: [BookTag]

    let existing: Book?

    @State private var title: String = ""
    @State private var author: String = ""
    @State private var pagesText: String = ""
    @State private var currentPageText: String = ""
    @State private var genre: BookGenre = .fiction
    @State private var format: BookFormat = .paper
    @State private var status: ReadingStatus = .wantToRead
    @State private var rating: Int = 0
    @State private var notes: String = ""
    @State private var selectedTagIDs: Set<PersistentIdentifier> = []
    @State private var newTagName: String = ""
    @State private var showValidation = false

    init(existing: Book? = nil) {
        self.existing = existing
    }

    private var isEditing: Bool { existing != nil }

    private var pages: Int { max(0, Int(pagesText) ?? 0) }
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && pages > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Book") {
                    TextField("Title", text: $title)
                        .accessibilityLabel("Title")
                    TextField("Author", text: $author)
                        .accessibilityLabel("Author")
                    HStack {
                        Text("Pages")
                        Spacer()
                        TextField("0", text: $pagesText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                            .accessibilityLabel("Total pages")
                    }
                    if showValidation && !isValid {
                        Text("A title and a page count above zero are required.")
                            .font(.footnote)
                            .foregroundStyle(Brand.danger)
                    }
                }

                Section("Genre") {
                    Picker("Genre", selection: $genre) {
                        ForEach(BookGenre.allCases) { g in
                            Label(g.label, systemImage: g.symbol).tag(g)
                        }
                    }
                }

                Section("Format") {
                    Picker("Format", selection: $format) {
                        ForEach(BookFormat.allCases) { f in
                            Label(f.label, systemImage: f.symbol).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(ReadingStatus.allCases) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    if status == .reading || status == .finished {
                        HStack {
                            Text("Current page")
                            Spacer()
                            TextField("0", text: $currentPageText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 90)
                                .accessibilityLabel("Current page")
                        }
                    }
                    if status == .finished {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Your rating").font(.subheadline).foregroundStyle(Brand.text2)
                            StarRating(rating: $rating)
                        }
                    }
                }

                Section("Tags") {
                    if allTags.isEmpty {
                        Text("No tags yet. Add one below to group books by mood or theme.")
                            .font(.footnote)
                            .foregroundStyle(Brand.text3)
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(allTags) { tag in
                                SelectChip(text: tag.name,
                                           isSelected: selectedTagIDs.contains(tag.persistentModelID)) {
                                    toggle(tag)
                                }
                            }
                        }
                    }
                    HStack {
                        TextField("New tag", text: $newTagName)
                            .accessibilityLabel("New tag name")
                        Button("Add") { addTag() }
                            .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...6)
                        .accessibilityLabel("Notes")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit book" : "Add book")
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
            .onAppear(perform: load)
        }
    }

    // MARK: Tag helpers

    private func toggle(_ tag: BookTag) {
        Haptics.tap()
        if selectedTagIDs.contains(tag.persistentModelID) {
            selectedTagIDs.remove(tag.persistentModelID)
        } else {
            selectedTagIDs.insert(tag.persistentModelID)
        }
    }

    private func addTag() {
        let name = newTagName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        // Avoid duplicates (case-insensitive).
        if let match = allTags.first(where: { $0.name.lowercased() == name.lowercased() }) {
            selectedTagIDs.insert(match.persistentModelID)
        } else {
            let palette: [UInt32] = [0xA66A3E, 0x4E6BA8, 0x3E9E78, 0xC0553E, 0x6B5B95, 0xC08A3E]
            let color = palette.randomElement() ?? 0xA66A3E
            let tag = BookTag(name: name, colorHex: String(format: "%06X", color))
            context.insert(tag)
            selectedTagIDs.insert(tag.persistentModelID)
        }
        newTagName = ""
    }

    // MARK: Load / save

    private func load() {
        if let book = existing {
            title = book.title
            author = book.author
            pagesText = "\(book.totalPages)"
            currentPageText = "\(book.currentPage)"
            genre = book.genre
            format = book.format
            status = book.status
            rating = book.rating
            notes = book.notes
            selectedTagIDs = Set(book.tags.map { $0.persistentModelID })
        } else {
            format = BookFormat(rawValue: defaultFormat) ?? .paper
        }
    }

    private func save() {
        guard isValid else { showValidation = true; return }

        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let chosenTags = allTags.filter { selectedTagIDs.contains($0.persistentModelID) }
        let total = max(1, pages)
        let current = min(max(0, Int(currentPageText) ?? 0), total)

        let book: Book
        if let existing {
            book = existing
            book.title = trimmedTitle
            book.author = author.trimmingCharacters(in: .whitespaces)
            book.totalPages = total
            book.genre = genre
            book.format = format
            book.notes = notes
            book.tags = chosenTags
        } else {
            book = Book(title: trimmedTitle,
                        author: author.trimmingCharacters(in: .whitespaces),
                        totalPages: total,
                        genre: genre,
                        status: status,
                        format: format,
                        notes: notes,
                        tags: chosenTags)
            context.insert(book)
        }

        // Apply status-dependent fields.
        applyStatus(to: book, current: current, total: total)
        book.rating = (book.status == .finished) ? rating : 0

        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func applyStatus(to book: Book, current: Int, total: Int) {
        book.status = status
        switch status {
        case .wantToRead:
            book.currentPage = 0
        case .reading:
            book.currentPage = min(current, total)
            if book.startedAt == nil { book.startedAt = .now }
            book.finishedAt = nil
        case .finished:
            book.currentPage = total
            if book.startedAt == nil { book.startedAt = .now }
            if book.finishedAt == nil { book.finishedAt = .now }
        case .dnf:
            book.currentPage = min(current, total)
            if book.startedAt == nil { book.startedAt = .now }
        }
    }
}
