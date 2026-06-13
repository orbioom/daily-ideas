import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Book.createdAt, order: .reverse) private var books: [Book]
    @State private var addingBook = false

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if books.isEmpty {
                    EmptyState(icon: "books.vertical",
                               title: "No books yet",
                               message: "Add the books you're reading, then start saving the lines worth keeping.",
                               actionTitle: "Add a book") { addingBook = true }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(books) { book in
                                NavigationLink(value: book) { BookCard(book: book) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Library")
            .navigationDestination(for: Book.self) { BookDetailView(book: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { addingBook = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add book")
                }
            }
            .sheet(isPresented: $addingBook) { BookEditor(book: nil) }
        }
    }
}

struct BookCard: View {
    let book: Book
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 10).fill(Theme.spine(book.spineColor))
                    .frame(height: 130)
                    .overlay(alignment: .topTrailing) {
                        if book.isFinished {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.white.opacity(0.9))
                                .padding(8)
                        }
                    }
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: BookCatalog.icon(for: book.category))
                        .font(.system(size: 20)).foregroundStyle(.white.opacity(0.9))
                    Text(book.displayTitle).font(Theme.serif(16, .bold)).foregroundStyle(.white)
                        .lineLimit(3).fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
            }
            VStack(alignment: .leading, spacing: 2) {
                if !book.author.isEmpty {
                    Text(book.author).font(.system(size: 13)).foregroundStyle(Theme.inkSoft).lineLimit(1)
                }
                Text("\(book.highlightCount) highlight\(book.highlightCount == 1 ? "" : "s")")
                    .font(.system(size: 12)).foregroundStyle(Theme.accent)
            }
            .padding(.top, 8).padding(.horizontal, 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.displayTitle), \(book.author), \(book.highlightCount) highlights")
    }
}

struct BookDetailView: View {
    @Bindable var book: Book
    @Environment(\.modelContext) private var context
    @State private var addingHighlight = false
    @State private var editingBook = false
    @State private var editingHighlight: Highlight?

    private var sorted: [Highlight] { book.highlights.sorted { $0.createdAt > $1.createdAt } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                Button { addingHighlight = true } label: {
                    Label("Add highlight", systemImage: "quote.opening")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accent))
                }
                if sorted.isEmpty {
                    Text("No highlights yet. Tap “Add highlight” to save your first line from this book.")
                        .font(.system(size: 14)).foregroundStyle(Theme.inkFaint)
                        .frame(maxWidth: .infinity).padding(.vertical, 30).multilineTextAlignment(.center)
                } else {
                    ForEach(sorted) { h in
                        Button { editingHighlight = h } label: { HighlightCell(highlight: h) }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button(role: .destructive) { context.delete(h) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Edit") { editingBook = true } }
        }
        .sheet(isPresented: $addingHighlight) { HighlightEditor(highlight: nil, presetBook: book) }
        .sheet(isPresented: $editingBook) { BookEditor(book: book) }
        .sheet(item: $editingHighlight) { HighlightEditor(highlight: $0, presetBook: book) }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 14) {
                RoundedRectangle(cornerRadius: 8).fill(Theme.spine(book.spineColor))
                    .frame(width: 56, height: 80)
                    .overlay(Image(systemName: BookCatalog.icon(for: book.category))
                        .foregroundStyle(.white.opacity(0.9)))
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.displayTitle).font(Theme.serif(24, .bold)).foregroundStyle(Theme.ink)
                    if !book.author.isEmpty {
                        Text(book.author).font(.system(size: 15)).foregroundStyle(Theme.inkSoft)
                    }
                    Text(book.category).font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.accent)
                    if book.isFinished {
                        Label("Finished", systemImage: "checkmark.seal")
                            .font(.system(size: 12)).foregroundStyle(Theme.inkSoft)
                    }
                }
                Spacer()
            }
        }
    }
}

struct HighlightCell: View {
    let highlight: Highlight
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            QuoteView(text: highlight.text, size: 17)
            HStack(spacing: 8) {
                if !highlight.location.isEmpty {
                    Text(highlight.location).font(.system(size: 12)).foregroundStyle(Theme.inkFaint)
                }
                if highlight.isFavorite {
                    Image(systemName: "heart.fill").font(.system(size: 11)).foregroundStyle(Theme.accent)
                }
                Spacer()
                if !highlight.tags.isEmpty {
                    Text(highlight.tags.map { "#\($0.name)" }.prefix(2).joined(separator: " "))
                        .font(.system(size: 12)).foregroundStyle(Theme.accent)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
    }
}
