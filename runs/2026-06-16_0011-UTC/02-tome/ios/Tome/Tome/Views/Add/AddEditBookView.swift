import SwiftUI
import SwiftData

/// Add a new book or edit an existing one.
struct AddEditBookView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var allTags: [Tag]

    /// nil = adding new.
    let book: Book?
    /// Optional shelf to default to when adding (e.g. from TBR).
    var defaultShelf: Shelf = .wantToRead

    @State private var title = ""
    @State private var author = ""
    @State private var pagesText = ""
    @State private var currentPageText = ""
    @State private var shelf: Shelf = .wantToRead
    @State private var format: BookFormat = .paperback
    @State private var seriesName = ""
    @State private var seriesNumberText = ""
    @State private var colorSeed = 0
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var newTagName = ""
    @State private var validationMessage: String?
    @State private var paywallReason: PaywallReason?

    private var isEditing: Bool { book != nil }

    var body: some View {
        NavigationStack {
            Form {
                coverPreviewSection
                detailsSection
                shelfSection
                tagsSection
                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.bad)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Book" : "Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .onAppear(perform: load)
        }
    }

    private var coverPreviewSection: some View {
        Section {
            HStack(spacing: 16) {
                BookCover(title: title.isEmpty ? "Untitled" : title,
                          author: author.isEmpty ? "Unknown" : author,
                          colorSeed: colorSeed,
                          initials: initials,
                          asGradient: settings.showCoversAsGradient)
                    .frame(width: 78)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cover color")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    Button {
                        colorSeed = Int.random(in: 0..<1000)
                        Haptics.selection(enabled: settings.hapticsEnabled)
                    } label: {
                        Label("Shuffle", systemImage: "shuffle")
                            .font(Theme.rounded(14, .semibold))
                    }
                }
                Spacer()
            }
            .listRowBackground(Theme.surface)
        }
    }

    private var detailsSection: some View {
        Section("Book") {
            TextField("Title", text: $title)
            TextField("Author", text: $author)
            HStack {
                Text("Pages").foregroundStyle(Theme.inkSoft)
                Spacer()
                TextField("0", text: $pagesText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 110)
            }
            Picker("Format", selection: $format) {
                ForEach(BookFormat.allCases) { f in
                    Label(f.displayName, systemImage: f.symbol).tag(f)
                }
            }
            TextField("Series (optional)", text: $seriesName)
            if !seriesName.trimmingCharacters(in: .whitespaces).isEmpty {
                HStack {
                    Text("Series #").foregroundStyle(Theme.inkSoft)
                    Spacer()
                    TextField("0", text: $seriesNumberText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                }
            }
        }
    }

    private var shelfSection: some View {
        Section("Shelf") {
            Picker("Shelf", selection: $shelf) {
                ForEach(Shelf.allCases) { s in
                    Label(s.displayName, systemImage: s.symbol).tag(s)
                }
            }
            if shelf == .reading || shelf == .finished {
                HStack {
                    Text("Current page").foregroundStyle(Theme.inkSoft)
                    Spacer()
                    TextField("0", text: $currentPageText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 110)
                }
            }
        }
    }

    private var tagsSection: some View {
        Section {
            if allTags.isEmpty {
                Text("No tags yet. Create moods or genres below.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(allTags) { tag in
                    Button {
                        toggle(tag)
                    } label: {
                        HStack {
                            Image(systemName: selectedTagIDs.contains(tag.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedTagIDs.contains(tag.id) ? Theme.accent : Theme.inkFaint)
                            Text(tag.name).foregroundStyle(Theme.ink)
                            Spacer()
                        }
                    }
                }
            }
            HStack {
                TextField("New tag", text: $newTagName)
                Button {
                    addTag()
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(Theme.accent)
                }
                .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Add tag")
            }
        } header: {
            HStack {
                Text("Tags & Moods")
                if !isPro { Spacer(); ProLockChip() }
            }
        } footer: {
            Text(isPro ? "Tag books by mood or genre to organize your shelves."
                       : "Custom tags are a Pro feature.")
        }
    }

    // MARK: - Actions

    private var initials: String {
        let t = title.trimmingCharacters(in: .whitespaces).first.map(String.init) ?? "?"
        let a = author.trimmingCharacters(in: .whitespaces).first.map(String.init) ?? ""
        return (t + a).uppercased()
    }

    private func load() {
        if let book {
            title = book.title
            author = book.author
            pagesText = String(book.pageCount)
            currentPageText = String(book.currentPage)
            shelf = book.shelf
            format = book.format
            seriesName = book.seriesName
            seriesNumberText = book.seriesNumber > 0 ? String(book.seriesNumber) : ""
            colorSeed = book.colorSeed
            selectedTagIDs = Set(book.tags.map { $0.id })
        } else {
            shelf = defaultShelf
            colorSeed = Int.random(in: 0..<1000)
        }
    }

    private func toggle(_ tag: Tag) {
        guard gateTags() else { return }
        if selectedTagIDs.contains(tag.id) {
            selectedTagIDs.remove(tag.id)
        } else {
            selectedTagIDs.insert(tag.id)
        }
        Haptics.selection(enabled: settings.hapticsEnabled)
    }

    private func addTag() {
        guard gateTags() else { return }
        let name = newTagName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        if let existing = allTags.first(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) {
            selectedTagIDs.insert(existing.id)
        } else {
            let t = Tag(name: name, colorSeed: name.count)
            context.insert(t)
            selectedTagIDs.insert(t.id)
        }
        newTagName = ""
        Haptics.tap(enabled: settings.hapticsEnabled)
    }

    /// Returns true if tagging is allowed; otherwise shows the paywall.
    private func gateTags() -> Bool {
        if isPro { return true }
        paywallReason = .tags
        return false
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else {
            validationMessage = "Please enter a title."
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        let pages = Int(pagesText.trimmingCharacters(in: .whitespaces)) ?? 0
        guard pages > 0 else {
            validationMessage = "Enter a page count greater than zero."
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        var current = Int(currentPageText.trimmingCharacters(in: .whitespaces)) ?? 0
        current = min(max(0, current), pages)
        let seriesNo = Int(seriesNumberText.trimmingCharacters(in: .whitespaces)) ?? 0
        let chosenTags = allTags.filter { selectedTagIDs.contains($0.id) }

        if let book {
            apply(to: book, title: trimmedTitle, pages: pages, current: current, seriesNo: seriesNo, tags: chosenTags)
        } else {
            let newBook = Book(title: trimmedTitle,
                               author: author.trimmingCharacters(in: .whitespaces),
                               pageCount: pages,
                               currentPage: current,
                               shelf: shelf,
                               format: format,
                               colorSeed: colorSeed,
                               seriesName: seriesName.trimmingCharacters(in: .whitespaces),
                               seriesNumber: seriesNo)
            newBook.tags = chosenTags
            applyShelfDates(to: newBook, oldShelf: nil)
            context.insert(newBook)
        }

        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func apply(to book: Book, title: String, pages: Int, current: Int, seriesNo: Int, tags: [Tag]) {
        let oldShelf = book.shelf
        book.title = title
        book.author = author.trimmingCharacters(in: .whitespaces)
        book.pageCount = pages
        book.currentPage = current
        book.format = format
        book.seriesName = seriesName.trimmingCharacters(in: .whitespaces)
        book.seriesNumber = seriesNo
        book.colorSeed = colorSeed
        book.tags = tags
        book.shelf = shelf
        applyShelfDates(to: book, oldShelf: oldShelf)
    }

    /// Keeps started/finished dates and currentPage consistent with the shelf.
    private func applyShelfDates(to book: Book, oldShelf: Shelf?) {
        switch book.shelf {
        case .reading:
            if book.startedDate == nil { book.startedDate = .now }
            book.finishedDate = nil
        case .finished:
            if book.startedDate == nil { book.startedDate = .now }
            book.finishedDate = book.finishedDate ?? .now
            book.currentPage = book.pageCount
        case .wantToRead:
            book.startedDate = nil
            book.finishedDate = nil
            book.currentPage = 0
        case .dnf:
            if book.startedDate == nil { book.startedDate = .now }
            book.finishedDate = nil
        }
    }
}
