import SwiftUI
import SwiftData

/// The full library as a grid of generated gradient posters, with search, filter, and sort.
struct LibraryScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Title.addedDate, order: .reverse) private var titles: [Title]

    @State private var search = ""
    @State private var filter: StatusFilter = .all
    @State private var sort: LibrarySort = .recentlyAdded
    @State private var showAdd = false
    @State private var showPaywall = false
    @State private var didLoadSort = false

    enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case watchlist = "Watchlist"
        case watching = "Watching"
        case watched = "Watched"
        var id: String { rawValue }
        var status: WatchStatus? {
            switch self {
            case .all: return nil
            case .watchlist: return .watchlist
            case .watching: return .watching
            case .watched: return .watched
            }
        }
    }

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 14)]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Library")
            .toolbar { toolbarContent }
            .searchable(text: $search, prompt: "Search titles, directors, genres")
            .navigationDestination(for: Title.self) { title in
                TitleDetailView(title: title)
            }
            .sheet(isPresented: $showAdd) {
                TitleEditorView(existing: nil, currentTitleCount: titles.count)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .titleLimit)
            }
            .onAppear {
                if !didLoadSort { sort = settings.defaultSort; didLoadSort = true }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Sort", selection: $sort) {
                    ForEach(LibrarySort.allCases) { option in
                        Label(option.rawValue, systemImage: option.systemImage).tag(option)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
            .accessibilityLabel("Sort library")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                addTapped()
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add title")
        }
    }

    @ViewBuilder
    private var content: some View {
        if titles.isEmpty {
            EmptyStateView(symbol: "film.stack",
                           title: "Your library is empty",
                           message: "Add the films and shows you've seen — or want to see — and they'll appear here as cinematic posters.",
                           actionTitle: "Add your first title") {
                addTapped()
            }
        } else {
            VStack(spacing: 0) {
                filterBar
                if displayed.isEmpty {
                    EmptyStateView(symbol: "magnifyingglass",
                                   title: "No matches",
                                   message: "Nothing fits that search or filter. Try a different term.")
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(displayed) { title in
                                NavigationLink(value: title) {
                                    posterCell(title)
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

    private var filterBar: some View {
        Picker("Filter", selection: $filter) {
            ForEach(StatusFilter.allCases) { f in
                Text(f.rawValue).tag(f)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func posterCell(_ title: Title) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            PosterView(title: title, asGradient: settings.showPostersAsGradient)
                .frame(height: 158)
            Text(title.name)
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            Text(String(title.year))
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    // MARK: Filtering + sorting

    private var displayed: [Title] {
        var list = titles
        if let status = filter.status {
            list = list.filter { $0.status == status }
        }
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            list = list.filter { t in
                t.name.lowercased().contains(q)
                || t.creator.lowercased().contains(q)
                || t.genresRaw.contains { $0.lowercased().contains(q) }
            }
        }
        return sorted(list)
    }

    private func sorted(_ list: [Title]) -> [Title] {
        switch sort {
        case .recentlyAdded:
            return list.sorted { $0.addedDate > $1.addedDate }
        case .rating:
            return list.sorted { ($0.rating ?? -1) > ($1.rating ?? -1) }
        case .title:
            return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .year:
            return list.sorted { $0.year > $1.year }
        }
    }

    private func addTapped() {
        if Pro.canAddTitle(currentCount: titles.count, isPro: isPro) {
            showAdd = true
            Haptics.tap(enabled: settings.hapticsEnabled)
        } else {
            showPaywall = true
            Haptics.warning(enabled: settings.hapticsEnabled)
        }
    }
}

#Preview {
    LibraryScreen()
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}
