import SwiftUI
import SwiftData

struct HighlightsView: View {
    @Query(sort: \Highlight.createdAt, order: .reverse) private var highlights: [Highlight]
    @Query(sort: \Tag.name) private var tags: [Tag]
    @State private var search = ""
    @State private var favoritesOnly = false
    @State private var selectedTag: String?
    @State private var editing: Highlight?

    private var filtered: [Highlight] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        return highlights.filter { h in
            (!favoritesOnly || h.isFavorite) &&
            (selectedTag == nil || h.tags.contains { $0.name == selectedTag }) &&
            (q.isEmpty || h.text.lowercased().contains(q) || h.note.lowercased().contains(q)
                || (h.book?.title.lowercased().contains(q) ?? false))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if highlights.isEmpty {
                    EmptyState(icon: "quote.bubble",
                               title: "No highlights yet",
                               message: "Save lines from your books and they'll all gather here, searchable and taggable.")
                } else {
                    VStack(spacing: 0) {
                        filterBar
                        if filtered.isEmpty {
                            EmptyState(icon: "magnifyingglass", title: "Nothing matches",
                                       message: "Try a different search or filter.")
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 10) {
                                    ForEach(filtered) { h in
                                        Button { editing = h } label: { HighlightRow(highlight: h) }
                                            .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16).padding(.vertical, 10)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Highlights")
            .searchable(text: $search, prompt: "Search highlights")
            .sheet(item: $editing) { HighlightEditor(highlight: $0, presetBook: nil) }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button { favoritesOnly.toggle(); Haptics.tap() } label: {
                    Label("Favorites", systemImage: favoritesOnly ? "heart.fill" : "heart")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(favoritesOnly ? .white : Theme.accent)
                        .padding(.horizontal, 11).padding(.vertical, 6)
                        .background(Capsule().fill(favoritesOnly ? Theme.accent : Theme.accentSoft))
                }
                ForEach(tags) { tag in
                    Button {
                        selectedTag = (selectedTag == tag.name) ? nil : tag.name; Haptics.tap()
                    } label: {
                        ThemeChip(text: "#\(tag.name)", selected: selectedTag == tag.name)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
        }
        .background(Theme.bg)
    }
}

struct HighlightRow: View {
    let highlight: Highlight
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            QuoteView(text: highlight.text, size: 17)
            HStack(spacing: 8) {
                if let book = highlight.book {
                    RoundedRectangle(cornerRadius: 2).fill(Theme.spine(book.spineColor)).frame(width: 3, height: 16)
                    Text(book.displayTitle).font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundStyle(Theme.inkSoft).lineLimit(1)
                }
                Spacer()
                if highlight.isFavorite {
                    Image(systemName: "heart.fill").font(.system(size: 11)).foregroundStyle(Theme.accent)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
    }
}
