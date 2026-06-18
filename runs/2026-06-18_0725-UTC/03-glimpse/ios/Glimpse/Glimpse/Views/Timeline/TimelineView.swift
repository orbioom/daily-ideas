import SwiftUI
import SwiftData

/// Reverse-chronological feed of moment cards with mood/tag/favorite filters
/// and caption search.
struct TimelineView: View {
    @Query(sort: \Moment.createdAt, order: .reverse) private var moments: [Moment]

    @State private var searchText = ""
    @State private var moodFilter: Mood?
    @State private var favoritesOnly = false
    @State private var tagFilter: String?

    private var allTags: [String] {
        var counts: [String: Int] = [:]
        for moment in moments {
            for tag in moment.tags { counts[tag, default: 0] += 1 }
        }
        return counts.sorted { $0.value > $1.value }.map { $0.key }
    }

    private var filtered: [Moment] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return moments.filter { moment in
            if let moodFilter, moment.mood != moodFilter { return false }
            if favoritesOnly, !moment.isFavorite { return false }
            if let tagFilter, !moment.tags.contains(tagFilter) { return false }
            if !query.isEmpty {
                let haystack = (moment.caption + " " + moment.title + " " + moment.tags.joined(separator: " ")).lowercased()
                if !haystack.contains(query) { return false }
            }
            return true
        }
    }

    private var hasActiveFilter: Bool {
        moodFilter != nil || favoritesOnly || tagFilter != nil || !searchText.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if moments.isEmpty {
                    EmptyStateView(
                        symbol: "rectangle.stack",
                        title: "Your timeline is waiting",
                        message: "Captured moments appear here as a beautiful, scrollable feed."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            filterBar
                            if filtered.isEmpty {
                                EmptyStateView(
                                    symbol: "line.3.horizontal.decrease.circle",
                                    title: "Nothing matches",
                                    message: "Try clearing a filter or searching for something else.",
                                    actionTitle: "Clear filters",
                                    action: clearFilters
                                )
                                .padding(.top, 20)
                            } else {
                                ForEach(filtered) { moment in
                                    NavigationLink {
                                        MomentDetailView(moment: moment)
                                    } label: {
                                        MomentCard(moment: moment)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Timeline")
            .searchable(text: $searchText, prompt: "Search captions & tags")
        }
    }

    private var filterBar: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "Favorites", systemImage: "heart.fill", selected: favoritesOnly) {
                        favoritesOnly.toggle()
                    }
                    ForEach(Mood.allCases) { mood in
                        FilterChip(
                            label: mood.label,
                            systemImage: mood.symbol,
                            selected: moodFilter == mood,
                            tint: mood.color
                        ) {
                            moodFilter = (moodFilter == mood) ? nil : mood
                        }
                    }
                }
            }
            if !allTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(allTags.prefix(20), id: \.self) { tag in
                            Button {
                                tagFilter = (tagFilter == tag) ? nil : tag
                            } label: {
                                TagChip(tag: tag, selected: tagFilter == tag)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            if hasActiveFilter {
                HStack {
                    Text("\(filtered.count) shown")
                        .font(Theme.rounded(12, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Button("Clear", action: clearFilters)
                        .font(Theme.rounded(12, .semibold))
                        .tint(Theme.accent)
                }
            }
        }
    }

    private func clearFilters() {
        moodFilter = nil
        favoritesOnly = false
        tagFilter = nil
        searchText = ""
    }
}

struct FilterChip: View {
    let label: String
    var systemImage: String?
    let selected: Bool
    var tint: Color = Theme.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 12, weight: .semibold))
                }
                Text(label).font(Theme.rounded(13, .semibold))
            }
            .foregroundStyle(selected ? .white : Theme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                selected ? AnyShapeStyle(tint) : AnyShapeStyle(Theme.surfaceAlt),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
