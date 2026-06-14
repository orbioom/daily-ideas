import SwiftUI
import SwiftData

/// Collection — owned grid of vinyl-cover cards with search, filter and sort.
struct CollectionScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Record.artist) private var allRecords: [Record]

    @State private var search = ""
    @State private var sort: CollectionSort = .artist
    @State private var genreFilter: Genre?
    @State private var formatFilter: Format?
    @State private var decadeFilter: Int?
    @State private var showAdd = false
    @State private var paywallReason: PaywallReason?
    @State private var didLoadSort = false

    private var owned: [Record] { allRecords.filter { $0.status == .owned } }

    private var ownedCount: Int { owned.count }

    /// Decades present in the owned collection, descending.
    private var availableDecades: [Int] {
        let set = Set(owned.compactMap { $0.decade })
        return set.sorted(by: >)
    }

    private var filtered: [Record] {
        var list = owned
        if let genreFilter { list = list.filter { $0.genre == genreFilter } }
        if let formatFilter { list = list.filter { $0.format == formatFilter } }
        if let decadeFilter { list = list.filter { $0.decade == decadeFilter } }
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.title.lowercased().contains(q)
                    || $0.artist.lowercased().contains(q)
                    || $0.label.lowercased().contains(q)
            }
        }
        return sorted(list)
    }

    private func sorted(_ list: [Record]) -> [Record] {
        switch sort {
        case .artist:
            return list.sorted { lhs, rhs in
                let a = lhs.artist.localizedCaseInsensitiveCompare(rhs.artist)
                if a != .orderedSame { return a == .orderedAscending }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        case .title:
            return list.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .added:
            return list.sorted { $0.addedAt > $1.addedAt }
        case .value:
            return list.sorted { $0.estValue > $1.estValue }
        case .mostSpun:
            return list.sorted { $0.spinCount > $1.spinCount }
        }
    }

    private let columns = [GridItem(.adaptive(minimum: 158), spacing: 14)]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Collection")
            .searchable(text: $search, prompt: "Artist, title or label")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { sortMenu }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { attemptAdd() } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add record")
                }
            }
            .navigationDestination(for: Record.self) { rec in
                RecordDetailView(record: rec)
            }
            .sheet(isPresented: $showAdd) {
                RecordEditorView(record: nil, initialStatus: .owned)
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
            .onAppear {
                if !didLoadSort { sort = settings.defaultSort; didLoadSort = true }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if owned.isEmpty {
            EmptyStateView(symbol: "square.grid.2x2",
                           title: "Your crate is empty",
                           message: "Add your first record, or load a sample collection from Settings to see Crate in action.",
                           actionTitle: "Add a record") { attemptAdd() }
        } else {
            ScrollView {
                filterBar
                if filtered.isEmpty {
                    EmptyStateView(symbol: "magnifyingglass",
                                   title: "No matches",
                                   message: "Nothing in your crate matches these filters. Try clearing them.",
                                   actionTitle: "Clear filters") { clearFilters() }
                        .padding(.top, 40)
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(filtered) { rec in
                            NavigationLink(value: rec) {
                                RecordCard(record: rec,
                                           hideValue: settings.hideValues,
                                           moneyText: settings.formatMoney)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    Button("All genres") { genreFilter = nil }
                    ForEach(Genre.allCases) { g in
                        Button(g.rawValue) { genreFilter = g }
                    }
                } label: {
                    filterChip(genreFilter?.rawValue ?? "Genre", active: genreFilter != nil, symbol: "guitars")
                }
                Menu {
                    Button("All formats") { formatFilter = nil }
                    ForEach(Format.allCases) { f in
                        Button(f.display) { formatFilter = f }
                    }
                } label: {
                    filterChip(formatFilter?.display ?? "Format", active: formatFilter != nil, symbol: "opticaldisc")
                }
                Menu {
                    Button("All decades") { decadeFilter = nil }
                    ForEach(availableDecades, id: \.self) { d in
                        Button("\(d)s") { decadeFilter = d }
                    }
                } label: {
                    filterChip(decadeFilter.map { "\($0)s" } ?? "Decade", active: decadeFilter != nil, symbol: "calendar")
                }
                if genreFilter != nil || formatFilter != nil || decadeFilter != nil {
                    Button { clearFilters() } label: {
                        Label("Clear", systemImage: "xmark.circle.fill")
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(Theme.bad)
                    }
                    .padding(.leading, 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func filterChip(_ text: String, active: Bool, symbol: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol).font(.system(size: 11, weight: .semibold))
            Text(text).font(Theme.rounded(13, .semibold))
            Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold))
        }
        .foregroundStyle(active ? .white : Theme.ink)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(active ? Theme.accent : Theme.surfaceAlt))
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort", selection: $sort) {
                ForEach(CollectionSort.allCases) { s in
                    Label(s.rawValue, systemImage: s.symbol).tag(s)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .accessibilityLabel("Sort: \(sort.rawValue)")
        }
    }

    private func attemptAdd() {
        if Pro.canAddOwned(currentOwnedCount: ownedCount, isPro: isPro) {
            showAdd = true
        } else {
            paywallReason = .collectionLimit
        }
    }

    private func clearFilters() {
        genreFilter = nil
        formatFilter = nil
        decadeFilter = nil
    }
}
