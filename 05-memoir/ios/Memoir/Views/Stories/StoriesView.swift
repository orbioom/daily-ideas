import SwiftUI
import SwiftData

struct StoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoryEntry.createdDate, order: .reverse) private var entries: [StoryEntry]

    @State private var searchText = ""
    @State private var selectedFilter: StoryFilter = .all
    @State private var selectedEraFilter: LifeEra? = nil

    enum StoryFilter: String, CaseIterable {
        case all       = "All"
        case favorites = "Favorites"
        case byEra     = "By Era"
    }

    private var filteredEntries: [StoryEntry] {
        var result = entries

        // Text search
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(q) || $0.bodyText.lowercased().contains(q)
            }
        }

        switch selectedFilter {
        case .all:
            break
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .byEra:
            if let era = selectedEraFilter {
                result = result.filter { $0.era == era }
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats header
                StatsHeaderView(entries: entries)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))

                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(StoryFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter
                            ) {
                                withAnimation(.spring(duration: 0.25)) {
                                    selectedFilter = filter
                                    if filter != .byEra {
                                        selectedEraFilter = nil
                                    }
                                }
                            }
                        }

                        if selectedFilter == .byEra {
                            Divider()
                                .frame(height: 24)
                            ForEach(LifeEra.allCases, id: \.self) { era in
                                FilterChip(
                                    title: era.displayName,
                                    isSelected: selectedEraFilter == era,
                                    color: MemoirTheme.eraColor(era)
                                ) {
                                    withAnimation(.spring(duration: 0.25)) {
                                        selectedEraFilter = selectedEraFilter == era ? nil : era
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color(.systemBackground))

                Divider()

                // Entry list
                if filteredEntries.isEmpty {
                    EmptyStoriesView(hasEntries: !entries.isEmpty)
                } else {
                    List {
                        ForEach(filteredEntries) { entry in
                            NavigationLink {
                                StoryDetailView(entry: entry)
                            } label: {
                                EntryRow(entry: entry)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    toggleFavorite(entry)
                                } label: {
                                    Label(
                                        entry.isFavorite ? "Unfavorite" : "Favorite",
                                        systemImage: entry.isFavorite ? "star.slash" : "star.fill"
                                    )
                                }
                                .tint(MemoirTheme.warmAmber)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteEntry(entry)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .background(MemoirTheme.parchment.opacity(0.3))
                }
            }
            .background(MemoirTheme.parchment.opacity(0.3).ignoresSafeArea())
            .navigationTitle("Stories")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search your stories…")
        }
    }

    private func toggleFavorite(_ entry: StoryEntry) {
        entry.isFavorite.toggle()
        try? modelContext.save()
        if MemoirSettings.hapticFeedback {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func deleteEntry(_ entry: StoryEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
}

// MARK: - StatsHeaderView

private struct StatsHeaderView: View {
    let entries: [StoryEntry]

    private var engine: MemoirEngine { MemoirEngine() }

    private var totalWords: Int {
        entries.reduce(0) { $0 + $1.wordCount }
    }

    private var streak: Int {
        engine.streakDays(from: entries)
    }

    var body: some View {
        HStack(spacing: 0) {
            StatPill(value: "\(entries.count)", label: "Entries", icon: "book.pages")
            Divider().frame(height: 32)
            StatPill(value: totalWords.formatted(), label: "Words", icon: "text.alignleft")
            Divider().frame(height: 32)
            StatPill(value: "\(streak)", label: streak == 1 ? "Day Streak" : "Day Streak", icon: "flame.fill")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(MemoirTheme.parchment)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        )
    }
}

private struct StatPill: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(MemoirTheme.warmAmber)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(MemoirTheme.inkBrown)
                Text(label)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - FilterChip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = MemoirTheme.warmAmber
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected ? color : color.opacity(0.10)
                )
                .foregroundColor(isSelected ? .white : color)
                .clipShape(Capsule())
        }
    }
}

// MARK: - EntryRow

private struct EntryRow: View {
    let entry: StoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(MemoirTheme.inkBrown)
                        .lineLimit(1)

                    Text(entry.bodyText)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if entry.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(MemoirTheme.warmAmber)
                }
            }

            HStack(spacing: 8) {
                // Era badge
                Text(entry.era.displayName)
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(MemoirTheme.eraColor(entry.era).opacity(0.18))
                    .foregroundColor(MemoirTheme.eraColor(entry.era))
                    .clipShape(Capsule())

                // Mood icon
                Image(systemName: entry.mood.icon)
                    .font(.caption2)
                    .foregroundColor(MemoirTheme.moodColor(entry.mood))

                Spacer()

                Text("\(entry.wordCount) words")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(entry.createdDate.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
        )
    }
}

// MARK: - EmptyStoriesView

private struct EmptyStoriesView: View {
    let hasEntries: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: hasEntries ? "magnifyingglass" : "book.closed")
                .font(.system(size: 48))
                .foregroundColor(MemoirTheme.warmAmber.opacity(0.5))
            Text(hasEntries ? "No matching stories" : "No stories yet")
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundColor(MemoirTheme.inkBrown)
            Text(hasEntries
                ? "Try a different search or filter."
                : "Head to the Write tab to capture your first memory.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}
