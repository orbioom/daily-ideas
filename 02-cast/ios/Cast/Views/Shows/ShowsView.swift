import SwiftUI
import SwiftData

struct ShowsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PodcastShow.title) private var shows: [PodcastShow]
    @State private var showAddSheet = false
    @State private var searchText = ""
    @State private var selectedGenre: PodcastGenre? = nil

    private var filtered: [PodcastShow] {
        var result = shows
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.host.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let g = selectedGenre { result = result.filter { $0.genre == g } }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !shows.isEmpty {
                    genreFilter
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }

                if filtered.isEmpty && shows.isEmpty {
                    emptyState
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List(filtered) { show in
                        NavigationLink(destination: ShowDetailView(show: show)) {
                            ShowRow(show: show)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { context.delete(show) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Shows")
            .searchable(text: $searchText, prompt: "Search shows")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus").accessibilityLabel("Add show")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) { AddShowView() }
        }
    }

    private var genreFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All", isSelected: selectedGenre == nil) {
                    selectedGenre = nil
                }
                ForEach(PodcastGenre.allCases, id: \.self) { g in
                    filterChip(label: g.rawValue, isSelected: selectedGenre == g) {
                        selectedGenre = selectedGenre == g ? nil : g
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? CastTheme.purple : Color(.secondarySystemGroupedBackground),
                            in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Shows Yet", systemImage: "mic.circle")
        } description: {
            Text("Add your favorite podcasts to start tracking your listening.")
        } actions: {
            Button("Add a Show") { showAddSheet = true }
                .buttonStyle(.borderedProminent)
        }
    }
}

struct ShowRow: View {
    let show: PodcastShow

    var body: some View {
        HStack(spacing: 12) {
            ShowArtwork(show: show, size: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text(show.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if !show.host.isEmpty {
                    Text(show.host)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 6) {
                    Text(show.genre.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(CastTheme.genreColor(show.genre).opacity(0.15), in: Capsule())
                        .foregroundStyle(CastTheme.genreColor(show.genre))
                    if show.listenedCount > 0 {
                        Text("\(show.listenedCount) ep\(show.listenedCount == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if show.unlistenedCount > 0 {
                Text("\(show.unlistenedCount)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 22)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(CastTheme.purple, in: Capsule())
                    .accessibilityLabel("\(show.unlistenedCount) in queue")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(show.title)\(show.host.isEmpty ? "" : " by \(show.host)"), \(show.genre.rawValue), \(show.listenedCount) episodes listened")
    }
}
