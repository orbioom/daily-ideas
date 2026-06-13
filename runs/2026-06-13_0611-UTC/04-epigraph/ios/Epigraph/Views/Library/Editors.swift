import SwiftUI
import SwiftData

struct BookEditor: View {
    let book: Book?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var title = ""
    @State private var author = ""
    @State private var category = "Nonfiction"
    @State private var spineColor = 0
    @State private var isFinished = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    Picker("Category", selection: $category) {
                        ForEach(BookCatalog.categories, id: \.self) { Text($0).tag($0) }
                    }
                    Toggle("Finished reading", isOn: $isFinished)
                }
                Section("Spine colour") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                        ForEach(Theme.spineColors.indices, id: \.self) { i in
                            Button { spineColor = i; Haptics.tap() } label: {
                                RoundedRectangle(cornerRadius: 8).fill(Theme.spine(i))
                                    .frame(height: 44)
                                    .overlay {
                                        if spineColor == i {
                                            Image(systemName: "checkmark").foregroundStyle(.white).font(.system(size: 16, weight: .bold))
                                        }
                                    }
                            }.buttonStyle(.plain)
                        }
                    }
                }
                if book != nil {
                    Section {
                        Button("Delete book", role: .destructive) {
                            if let book { context.delete(book) }
                            dismiss()
                        }
                    } footer: {
                        Text("Deleting a book removes its highlights too.")
                    }
                }
            }
            .navigationTitle(book == nil ? "New book" : "Edit book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                guard let book else { return }
                title = book.title; author = book.author; category = book.category
                spineColor = book.spineColor; isFinished = book.isFinished
            }
        }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        if let book {
            book.title = t; book.author = author; book.category = category
            book.spineColor = spineColor; book.isFinished = isFinished
        } else {
            context.insert(Book(title: t, author: author, category: category,
                                spineColor: spineColor, isFinished: isFinished))
        }
        Haptics.success(); dismiss()
    }
}

struct HighlightEditor: View {
    let highlight: Highlight?
    var presetBook: Book?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Book.title) private var books: [Book]
    @Query(sort: \Tag.name) private var allTags: [Tag]

    @State private var text = ""
    @State private var note = ""
    @State private var location = ""
    @State private var selectedBook: Book?
    @State private var isFavorite = false
    @State private var tagNames: Set<String> = []
    @State private var newTag = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Highlight") {
                    TextField("Paste or type the quote…", text: $text, axis: .vertical)
                        .lineLimit(3...8).font(Theme.serif(16))
                }
                Section("Your note") {
                    TextField("Why it matters to you (optional)", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                }
                Section {
                    Picker("Book", selection: $selectedBook) {
                        Text("None").tag(Optional<Book>.none)
                        ForEach(books) { Text($0.displayTitle).tag(Optional($0)) }
                    }
                    TextField("Page / location (optional)", text: $location)
                    Toggle("Favorite", isOn: $isFavorite)
                }
                Section("Themes") {
                    if !allTags.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(allTags) { tag in
                                Button {
                                    if tagNames.contains(tag.name) { tagNames.remove(tag.name) }
                                    else { tagNames.insert(tag.name) }
                                    Haptics.tap()
                                } label: { ThemeChip(text: "#\(tag.name)", selected: tagNames.contains(tag.name)) }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    HStack {
                        TextField("New theme", text: $newTag)
                            .autocorrectionDisabled().textInputAutocapitalization(.never)
                            .onSubmit(addNewTag)
                        Button("Add", action: addNewTag).disabled(cleanedNewTag.isEmpty)
                    }
                }
                if highlight != nil {
                    Section {
                        Button("Delete highlight", role: .destructive) {
                            if let highlight { context.delete(highlight) }
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(highlight == nil ? "New highlight" : "Edit highlight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var cleanedNewTag: String {
        newTag.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "#", with: "").lowercased()
    }

    private func addNewTag() {
        let name = cleanedNewTag
        guard !name.isEmpty else { return }
        if allTags.first(where: { $0.name == name }) == nil {
            context.insert(Tag(name: name))
        }
        tagNames.insert(name)
        newTag = ""
        Haptics.tap()
    }

    private func load() {
        if let highlight {
            text = highlight.text; note = highlight.note; location = highlight.location
            selectedBook = highlight.book; isFavorite = highlight.isFavorite
            tagNames = Set(highlight.tags.map { $0.name })
        } else {
            selectedBook = presetBook
        }
    }

    private func resolveTags() -> [Tag] {
        tagNames.compactMap { name in
            allTags.first(where: { $0.name == name }) ?? {
                let t = Tag(name: name); context.insert(t); return t
            }()
        }
    }

    private func save() {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        let tags = resolveTags()
        if let highlight {
            highlight.text = t; highlight.note = note; highlight.location = location
            highlight.book = selectedBook; highlight.isFavorite = isFavorite
            highlight.tags = tags
        } else {
            let h = Highlight(text: t, note: note, location: location, book: selectedBook)
            h.isFavorite = isFavorite
            h.tags = tags
            context.insert(h)
        }
        Haptics.success(); dismiss()
    }
}
