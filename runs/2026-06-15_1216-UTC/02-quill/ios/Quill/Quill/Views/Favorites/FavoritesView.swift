import SwiftData
import SwiftUI

/// Aggregates favorite notebooks and recently edited pages. Tapping a recent
/// page jumps straight into the editor at that page.
struct FavoritesView: View {
    @Query(filter: #Predicate<Notebook> { $0.isFavorite },
           sort: \Notebook.updatedAt, order: .reverse)
    private var favoriteNotebooks: [Notebook]

    @Query(sort: \Page.updatedAt, order: .reverse)
    private var recentPages: [Page]

    @State private var detailTarget: Notebook?
    @State private var editorRoute: EditorRoute?

    private let columns = [GridItem(.adaptive(minimum: 140, maximum: 190), spacing: 22)]

    private var topRecent: [Page] {
        // Only pages that still belong to a notebook and have some content or recency.
        Array(recentPages.filter { $0.notebook != nil }.prefix(10))
    }

    var body: some View {
        Group {
            if favoriteNotebooks.isEmpty && topRecent.isEmpty {
                EmptyStateView(
                    icon: "star",
                    title: "Nothing here yet",
                    message: "Favorite a notebook or start writing — your favorites and recent pages will appear here for quick access."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Favorites")
        .navigationDestination(item: $detailTarget) { notebook in
            NotebookDetailView(notebook: notebook)
        }
        .navigationDestination(item: $editorRoute) { route in
            PageEditorView(notebook: route.notebook, currentIndex: route.index)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                if !favoriteNotebooks.isEmpty {
                    section(title: "Favorite Notebooks") {
                        LazyVGrid(columns: columns, spacing: 26) {
                            ForEach(favoriteNotebooks) { notebook in
                                Button {
                                    detailTarget = notebook
                                } label: {
                                    BookCover(
                                        title: notebook.title,
                                        colorHex: notebook.coverColorHex,
                                        pageCount: notebook.pageCount,
                                        isFavorite: true,
                                        template: notebook.defaultTemplate
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                if !topRecent.isEmpty {
                    section(title: "Recently Edited") {
                        VStack(spacing: 10) {
                            ForEach(topRecent) { page in
                                recentRow(page)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Theme.rounded(20, .semibold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 20)
            content()
        }
    }

    private func recentRow(_ page: Page) -> some View {
        Button {
            openEditor(for: page)
        } label: {
            HStack(spacing: 14) {
                PageThumbnail(
                    thumbnailData: page.thumbnailData,
                    template: page.template,
                    pageNumber: pageNumber(of: page)
                )
                .frame(width: 54)

                VStack(alignment: .leading, spacing: 3) {
                    Text(page.notebook?.title ?? "Notebook")
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text("Page \(pageNumber(of: page)) · \(relative(page.updatedAt))")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(12)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(page.notebook?.title ?? "Notebook"), page \(pageNumber(of: page)), edited \(relative(page.updatedAt))")
        .accessibilityAddTraits(.isButton)
    }

    private func pageNumber(of page: Page) -> Int {
        guard let notebook = page.notebook,
              let idx = notebook.orderedPages.firstIndex(where: { $0.id == page.id })
        else { return 1 }
        return idx + 1
    }

    private func openEditor(for page: Page) {
        guard let notebook = page.notebook,
              let idx = notebook.orderedPages.firstIndex(where: { $0.id == page.id })
        else { return }
        editorRoute = EditorRoute(notebook: notebook, index: idx)
    }

    private func relative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}

/// Identifiable route into the editor from the Favorites screen.
struct EditorRoute: Identifiable, Hashable {
    let notebook: Notebook
    let index: Int
    var id: String { "\(notebook.id)-\(index)" }
}
