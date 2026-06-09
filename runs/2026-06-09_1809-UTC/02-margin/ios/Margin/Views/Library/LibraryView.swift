import SwiftUI
import SwiftData

/// Library tab. All books with search (title/author), a status filter, and a sort
/// control. Grouped into sections by status when no filter is active. Empty state
/// for both an empty library and a no-results search.
struct LibraryView: View {
    @Query(sort: \Book.addedAt, order: .reverse) private var books: [Book]
    @AppStorage("margin.sort") private var sortRaw = LibrarySort.recent.rawValue

    @State private var search = ""
    @State private var filter: ReadingStatus?
    @State private var showAdd = false

    private var sort: LibrarySort { LibrarySort(rawValue: sortRaw) ?? .recent }

    private var filtered: [Book] {
        var result = books
        if let filter { result = result.filter { $0.status == filter } }
        let query = search.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter {
                $0.title.lowercased().contains(query) || $0.author.lowercased().contains(query)
            }
        }
        return sortBooks(result)
    }

    private func sortBooks(_ list: [Book]) -> [Book] {
        switch sort {
        case .recent: return list.sorted { $0.addedAt > $1.addedAt }
        case .title: return list.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .rating: return list.sorted { $0.rating > $1.rating }
        }
    }

    /// Status sections (only used when no explicit filter is active).
    private var sections: [(status: ReadingStatus, books: [Book])] {
        ReadingStatus.allCases.compactMap { status in
            let group = filtered.filter { $0.status == status }
            return group.isEmpty ? nil : (status, group)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if books.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "books.vertical",
                                       title: "No books yet",
                                       message: "Tap the plus button to add your first book and start building your library.")
                            .glassCard()
                            .padding(20)
                    }
                } else {
                    content
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Library")
            .navigationDestination(for: Book.self) { BookDetailView(book: $0) }
            .searchable(text: $search, prompt: "Search title or author")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $sortRaw) {
                            ForEach(LibrarySort.allCases) { Text($0.label).tag($0.rawValue) }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Label("Add book", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) { BookEditorView() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                filterChips
                if filtered.isEmpty {
                    EmptyStateView(icon: "magnifyingglass",
                                   title: "No matches",
                                   message: "No books match your search and filter. Try clearing them.")
                        .glassCard()
                } else if filter == nil {
                    ForEach(sections, id: \.status) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                SectionTitle(text: section.status.label)
                                Spacer()
                                Text("\(section.books.count)")
                                    .font(Brand.mono(13))
                                    .foregroundStyle(Brand.text3)
                            }
                            ForEach(section.books) { LibraryRow(book: $0) }
                        }
                    }
                } else {
                    ForEach(filtered) { LibraryRow(book: $0) }
                }
            }
            .padding(20)
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SelectChip(text: "All", isSelected: filter == nil) {
                    Haptics.tap(); filter = nil
                }
                ForEach(ReadingStatus.allCases) { status in
                    SelectChip(text: status.label,
                               isSelected: filter == status,
                               systemImage: status.symbol) {
                        Haptics.tap()
                        filter = (filter == status) ? nil : status
                    }
                }
            }
            .padding(.horizontal, 1)
        }
    }
}

/// A single library row: spine, title/author, status, progress or rating.
private struct LibraryRow: View {
    let book: Book

    var body: some View {
        NavigationLink(value: book) {
            HStack(spacing: 14) {
                BookSpine(book: book, width: 40, height: 58)
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.text)
                        .lineLimit(2)
                    Text(book.author)
                        .font(.footnote)
                        .foregroundStyle(Brand.text2)
                        .lineLimit(1)
                    switch book.status {
                    case .reading:
                        ProgressBar(fraction: book.progress, height: 6)
                            .frame(maxWidth: 160)
                    case .finished:
                        StarRow(rating: book.rating)
                    default:
                        StatusPill(status: book.status)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Brand.text3)
                    .accessibilityHidden(true)
            }
            .glassCard(padding: 12)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.title) by \(book.author), \(book.status.label)")
    }
}
