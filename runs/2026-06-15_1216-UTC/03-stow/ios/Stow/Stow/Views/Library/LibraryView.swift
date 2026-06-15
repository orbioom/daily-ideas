import SwiftUI
import SwiftData

struct LibraryView: View {
    enum Section: String, CaseIterable, Identifiable {
        case tags = "Tags"
        case favorites = "Favorites"
        case highlights = "Highlights"
        var id: String { rawValue }
    }

    @State private var section: Section = .tags

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    Picker("Section", selection: $section) {
                        ForEach(Section.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    switch section {
                    case .tags: TagsLibrary()
                    case .favorites: FavoritesLibrary()
                    case .highlights: HighlightsLibrary()
                    }
                }
            }
            .navigationTitle("Library")
        }
    }
}

// MARK: - Tags

private struct TagsLibrary: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Tag.name) private var tags: [Tag]

    var body: some View {
        Group {
            if tags.isEmpty {
                EmptyStateView(
                    icon: "tag",
                    title: "No tags yet",
                    message: "Open an article and add a tag to start filing your library by topic."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(tags) { tag in
                            NavigationLink {
                                TagArticlesView(tag: tag)
                            } label: {
                                TagRow(tag: tag)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
}

private struct TagRow: View {
    @Bindable var tag: Tag

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: TagPalette.color(for: tag.colorHex)))
                .frame(width: 14, height: 14)
            VStack(alignment: .leading, spacing: 2) {
                Text(tag.name)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text("\(tag.articleCount) \(tag.articleCount == 1 ? "article" : "articles")")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkFaint)
        }
        .cardSurface(padding: 14)
        .accessibilityLabel("\(tag.name), \(tag.articleCount) articles")
    }
}

// MARK: - Favorites

private struct FavoritesLibrary: View {
    @Query(filter: #Predicate<Article> { $0.isFavorite }, sort: \Article.savedAt, order: .reverse)
    private var favorites: [Article]

    var body: some View {
        Group {
            if favorites.isEmpty {
                EmptyStateView(
                    icon: "heart",
                    title: "No favorites yet",
                    message: "Tap the heart on any article to keep it close. Your favorites gather here."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(favorites) { article in
                            NavigationLink {
                                ReaderView(article: article)
                            } label: {
                                ArticleCard(article: article)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
}

// MARK: - Highlights

private struct HighlightsLibrary: View {
    @Query(sort: \Highlight.createdAt, order: .reverse)
    private var highlights: [Highlight]

    /// Group highlights by their article title.
    private var grouped: [(title: String, article: Article?, items: [Highlight])] {
        let valid = highlights.filter { $0.article != nil }
        let dict = Dictionary(grouping: valid) { $0.article?.id ?? UUID() }
        return dict.values
            .compactMap { items -> (String, Article?, [Highlight])? in
                guard let first = items.first, let article = first.article else { return nil }
                return (article.title, article, items.sorted { $0.createdAt > $1.createdAt })
            }
            .sorted { $0.0.localizedCaseInsensitiveCompare($1.0) == .orderedAscending }
            .map { (title: $0.0, article: $0.1, items: $0.2) }
    }

    var body: some View {
        Group {
            if grouped.isEmpty {
                EmptyStateView(
                    icon: "highlighter",
                    title: "No highlights yet",
                    message: "Long-press a paragraph in the reader to save a highlight. They'll collect here by article."
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        ForEach(grouped, id: \.title) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                if let article = group.article {
                                    NavigationLink {
                                        ReaderView(article: article)
                                    } label: {
                                        HStack {
                                            Text(group.title)
                                                .font(Theme.serif(17, .semibold))
                                                .foregroundStyle(Theme.ink)
                                                .lineLimit(2)
                                            Spacer()
                                            Image(systemName: "arrow.up.right")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(Theme.accent)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                                ForEach(group.items) { h in
                                    HighlightCard(highlight: h)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
}

private struct HighlightCard: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    let highlight: Highlight

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.accent)
                .frame(width: 3)
            Text(highlight.text)
                .font(Theme.serif(15))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Theme.accentSoft.opacity(0.5), in: RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
        .contextMenu {
            Button(role: .destructive) {
                settings.haptic { Haptics.warning() }
                context.delete(highlight)
                try? context.save()
            } label: {
                Label("Delete highlight", systemImage: "trash")
            }
        }
        .accessibilityLabel("Highlight: \(highlight.text)")
    }
}
