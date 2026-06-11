import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query private var allEntries: [MediaEntry]
    @Environment(\.modelContext) private var ctx
    @State private var selectedStatus: WatchStatus? = nil
    @State private var selectedType: MediaType? = nil
    @State private var showAdd = false
    @State private var searchText = ""
    @AppStorage("librarySortOrder") private var sortOrder = "added"

    private var filtered: [MediaEntry] {
        var result = allEntries
        if let s = selectedStatus { result = result.filter { $0.status == s } }
        if let t = selectedType  { result = result.filter { $0.mediaType == t } }
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        switch sortOrder {
        case "title":  result.sort { $0.title < $1.title }
        case "year":   result.sort { $0.year > $1.year }
        case "rating": result.sort { $0.rating > $1.rating }
        default:       result.sort { $0.addedDate > $1.addedDate }
        }
        return result
    }

    private let columns = [GridItem(.adaptive(minimum: 130), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    filterBar
                    if filtered.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filtered) { entry in
                                NavigationLink(value: entry) {
                                    MediaCardView(entry: entry)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(entry.title)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 80)
            }
            .background(Theme.bgPrimary)
            .navigationTitle("Reel")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search your library")
            .navigationDestination(for: MediaEntry.self) { entry in
                MediaDetailView(entry: entry)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort by", selection: $sortOrder) {
                            Text("Date Added").tag("added")
                            Text("Title").tag("title")
                            Text("Year").tag("year")
                            Text("Rating").tag("rating")
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .accessibilityLabel("Sort options")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel("Add movie or show")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddMediaView()
            }
        }
    }

    @ViewBuilder
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", icon: "rectangle.grid.2x2", isSelected: selectedStatus == nil && selectedType == nil) {
                    selectedStatus = nil; selectedType = nil
                }
                FilterChip(label: "Watchlist", icon: "bookmark.fill", isSelected: selectedStatus == .watchlist) {
                    selectedStatus = selectedStatus == .watchlist ? nil : .watchlist
                }
                FilterChip(label: "Watching", icon: "play.circle.fill", isSelected: selectedStatus == .watching) {
                    selectedStatus = selectedStatus == .watching ? nil : .watching
                }
                FilterChip(label: "Watched", icon: "checkmark.circle.fill", isSelected: selectedStatus == .watched) {
                    selectedStatus = selectedStatus == .watched ? nil : .watched
                }
                Divider().frame(height: 24)
                FilterChip(label: "Movies", icon: "film", isSelected: selectedType == .movie) {
                    selectedType = selectedType == .movie ? nil : .movie
                }
                FilterChip(label: "Shows", icon: "tv", isSelected: selectedType == .show) {
                    selectedType = selectedType == .show ? nil : .show
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if allEntries.isEmpty {
            EmptyStateView(
                icon: "film.stack",
                title: "Your library is empty",
                subtitle: "Tap + to add movies and shows you've watched, are watching, or want to watch.",
                action: { showAdd = true },
                actionLabel: "Add Your First Title"
            )
            .frame(minHeight: 400)
        } else {
            EmptyStateView(
                icon: "magnifyingglass",
                title: "No results",
                subtitle: "Try adjusting your filters or search term."
            )
            .frame(minHeight: 300)
        }
    }
}

private struct FilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? Theme.gold : Theme.bgSecondary)
                .foregroundStyle(isSelected ? Color.black : Theme.textPrimary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
