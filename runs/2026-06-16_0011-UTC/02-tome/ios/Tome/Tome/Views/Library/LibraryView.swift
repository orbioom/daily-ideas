import SwiftUI
import SwiftData

/// Library: grid of generated covers with search, shelf filter, and sort.
struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var allBooks: [Book]

    @State private var path: [Book] = []
    @State private var searchText = ""
    @State private var shelfFilter: ShelfFilter = .all
    @State private var sort: LibrarySort = .recentlyAdded
    @State private var showAdd = false
    @State private var paywallReason: PaywallReason?

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 16)]

    enum ShelfFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case reading = "Reading"
        case wantToRead = "TBR"
        case finished = "Finished"
        case dnf = "DNF"
        var id: String { rawValue }

        var shelf: Shelf? {
            switch self {
            case .all: return nil
            case .reading: return .reading
            case .wantToRead: return .wantToRead
            case .finished: return .finished
            case .dnf: return .dnf
            }
        }
    }

    private var filtered: [Book] {
        var books = allBooks
        if let shelf = shelfFilter.shelf {
            books = books.filter { $0.shelf == shelf }
        }
        let query = searchText.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            books = books.filter {
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.author.localizedCaseInsensitiveContains(query) ||
                $0.seriesName.localizedCaseInsensitiveContains(query)
            }
        }
        return sorted(books)
    }

    private func sorted(_ books: [Book]) -> [Book] {
        switch sort {
        case .recentlyAdded:
            return books.sorted { $0.dateAdded > $1.dateAdded }
        case .title:
            return books.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .author:
            return books.sorted { $0.author.localizedCaseInsensitiveCompare($1.author) == .orderedAscending }
        case .rating:
            return books.sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
        case .progress:
            return books.sorted { $0.progress > $1.progress }
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Library")
            .searchable(text: $searchText, prompt: "Search title, author, series")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { sortMenu }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { addBook() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add book")
                }
            }
            .navigationDestination(for: Book.self) { BookDetailView(book: $0) }
            .sheet(isPresented: $showAdd) { AddEditBookView(book: nil) }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .onAppear { sort = settings.defaultSort }
        }
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort", selection: $sort) {
                ForEach(LibrarySort.allCases) { s in
                    Label(s.rawValue, systemImage: s.symbol).tag(s)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .accessibilityLabel("Sort books")
    }

    @ViewBuilder
    private var content: some View {
        if allBooks.isEmpty {
            EmptyStateView(symbol: "books.vertical",
                           title: "Your library is empty",
                           message: "Add your first book, or load a sample library from Settings.",
                           actionTitle: "Add a book") { addBook() }
        } else {
            VStack(spacing: 0) {
                filterBar
                if filtered.isEmpty {
                    Spacer()
                    EmptyStateView(symbol: "magnifyingglass",
                                   title: "No matches",
                                   message: "Try a different search or shelf filter.")
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 18) {
                            ForEach(filtered) { book in
                                gridItem(book)
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ShelfFilter.allCases) { f in
                    Button {
                        shelfFilter = f
                        Haptics.selection(enabled: settings.hapticsEnabled)
                    } label: {
                        Text(f.rawValue)
                            .font(Theme.rounded(13, .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(shelfFilter == f ? Theme.accent : Theme.surfaceAlt)
                            )
                            .foregroundStyle(shelfFilter == f ? .white : Theme.inkSoft)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }

    private func gridItem(_ book: Book) -> some View {
        Button {
            path.append(book)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    BookCover(title: book.title, author: book.author,
                              colorSeed: book.colorSeed, initials: book.coverInitials,
                              asGradient: settings.showCoversAsGradient)
                    if book.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(Circle().fill(Theme.accent))
                            .padding(6)
                            .accessibilityHidden(true)
                    }
                }
                Text(book.title)
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                if book.shelf == .reading {
                    ProgressView(value: book.progress).tint(Theme.accent)
                } else if let rating = book.rating, rating > 0 {
                    StarRow(rating: rating, size: 9)
                } else {
                    Text(book.shelf.shortName)
                        .font(Theme.rounded(11, .medium))
                        .foregroundStyle(book.shelf.tint)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.title) by \(book.author), \(book.shelf.displayName)")
        .accessibilityHint("Opens book details")
    }

    private func addBook() {
        if !isPro && allBooks.count >= Pro.freeBookLimit {
            paywallReason = .bookLimit
            Haptics.warning(enabled: settings.hapticsEnabled)
        } else {
            showAdd = true
        }
    }
}
