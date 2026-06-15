import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    @Query(filter: #Predicate<Article> { $0.isArchived }, sort: \Article.savedAt, order: .reverse)
    private var archived: [Article]

    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Group {
                    if archived.isEmpty {
                        EmptyStateView(
                            icon: "archivebox",
                            title: "Nothing archived yet",
                            message: "When you finish an article, mark it read and it lands here — out of the way but never lost."
                        )
                    } else if filtered.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No matches",
                            message: "Try a different search."
                        )
                    } else {
                        listView
                    }
                }
            }
            .navigationTitle("Archive")
            .searchable(text: $searchText, prompt: "Search archive")
        }
    }

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filtered) { article in
                    SwipeRowArchive(
                        restore: { restore(article) },
                        delete: { delete(article) }
                    ) {
                        NavigationLink {
                            ReaderView(article: article)
                        } label: {
                            ArticleCard(article: article)
                        }
                        .buttonStyle(.plain)
                    }
                    .contextMenu {
                        Button { restore(article) } label: {
                            Label("Restore", systemImage: "tray.and.arrow.up")
                        }
                        Button(role: .destructive) { delete(article) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private var filtered: [Article] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return archived }
        return archived.filter {
            $0.title.lowercased().contains(query) ||
            $0.siteName.lowercased().contains(query)
        }
    }

    private func restore(_ article: Article) {
        settings.haptic { Haptics.tap() }
        withAnimation { article.isArchived = false }
        try? context.save()
    }

    private func delete(_ article: Article) {
        settings.haptic { Haptics.warning() }
        withAnimation { context.delete(article) }
        try? context.save()
    }
}

/// A two-action swipe row for the archive (restore / delete).
struct SwipeRowArchive<Content: View>: View {
    var restore: () -> Void
    var delete: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var offset: CGFloat = 0
    @GestureState private var dragging: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let actionWidth: CGFloat = 70
    private var revealWidth: CGFloat { actionWidth * 2 + 8 }

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 6) {
                button("Restore", "tray.and.arrow.up.fill", Theme.good) { restore(); offset = 0 }
                button("Delete", "trash.fill", Theme.bad) { delete() }
            }
            .padding(.trailing, 4)
            .opacity(offset < -8 ? 1 : 0)

            content()
                .offset(x: offset + dragging)
                .gesture(
                    DragGesture(minimumDistance: 16)
                        .updating($dragging) { value, state, _ in
                            let t = value.translation.width
                            if offset == 0 { state = min(0, max(-revealWidth, t)) }
                            else { state = max(-revealWidth - offset, min(-offset, t)) }
                        }
                        .onEnded { value in
                            let total = offset + value.translation.width
                            offset = total < -revealWidth / 2 ? -revealWidth : 0
                        }
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.85), value: offset)
    }

    private func button(_ title: String, _ icon: String, _ tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                Text(title).font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(width: actionWidth)
            .frame(maxHeight: .infinity)
            .background(tint, in: RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
        }
        .accessibilityLabel(title)
    }
}
