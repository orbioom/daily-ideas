import SwiftUI
import SwiftData

/// The ranked list of visited restaurants — the heart of Relish.
struct ListScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query private var allRestaurants: [Restaurant]

    @State private var searchText = ""
    @State private var sort: ListSort = .rank
    @State private var cuisineFilter: Cuisine?
    @State private var cityFilter: String?
    @State private var sentimentFilter: Sentiment?
    @State private var showAdd = false
    @State private var didSetDefaultSort = false

    private var visited: [Restaurant] {
        allRestaurants.filter { !$0.isWishlist && $0.sentiment != nil }
    }

    private var scoreBook: ScoreBook { ScoreBook(allRestaurants: allRestaurants) }

    private var availableCities: [String] {
        Array(Set(visited.map { $0.city.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty })).sorted()
    }

    private var availableCuisines: [Cuisine] {
        Array(Set(visited.map { $0.cuisine })).sorted { $0.rawValue < $1.rawValue }
    }

    /// Rank lookup: position in full ranked order (1-based) regardless of filters.
    private var rankLookup: [UUID: Int] {
        let ordered = visited.sorted { $0.rankIndex < $1.rankIndex }
        var map: [UUID: Int] = [:]
        for (i, r) in ordered.enumerated() { map[r.id] = i + 1 }
        return map
    }

    private var filtered: [Restaurant] {
        let book = scoreBook
        var list = visited

        if let cuisineFilter { list = list.filter { $0.cuisine == cuisineFilter } }
        if let cityFilter { list = list.filter { $0.city.trimmingCharacters(in: .whitespaces) == cityFilter } }
        if let sentimentFilter { list = list.filter { $0.sentiment == sentimentFilter } }

        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.name.lowercased().contains(q) ||
                $0.city.lowercased().contains(q) ||
                $0.cuisine.rawValue.lowercased().contains(q)
            }
        }

        switch sort {
        case .rank: list.sort { $0.rankIndex < $1.rankIndex }
        case .score: list.sort { book.score($0) > book.score($1) }
        case .name: list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .recent: list.sort { $0.dateAdded > $1.dateAdded }
        }
        return list
    }

    private var hasActiveFilter: Bool {
        cuisineFilter != nil || cityFilter != nil || sentimentFilter != nil
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Theme.bg.ignoresSafeArea()
                content
                addButton
            }
            .navigationTitle("Your List")
            .toolbar { toolbarContent }
            .searchable(text: $searchText, prompt: "Search name, city, cuisine")
            .sheet(isPresented: $showAdd) {
                AddFlowView(allRestaurants: allRestaurants)
            }
        }
        .onAppear {
            guard !didSetDefaultSort else { return }
            sort = settings.defaultSort
            didSetDefaultSort = true
        }
    }

    @ViewBuilder
    private var content: some View {
        if visited.isEmpty {
            EmptyStateView(symbol: "list.number",
                           title: "Your list is empty",
                           message: "Add the first place you've been and Relish will start building your personal ranking.",
                           actionTitle: "Add a place") { showAdd = true }
        } else if filtered.isEmpty {
            EmptyStateView(symbol: "magnifyingglass",
                           title: "No matches",
                           message: "Nothing fits those filters. Try clearing them or searching differently.",
                           actionTitle: "Clear filters") { clearFilters() }
        } else {
            listBody
        }
    }

    private var listBody: some View {
        List {
            if settings.showTierHeaders && sort == .rank && !hasActiveFilter && searchText.isEmpty {
                ForEach(Sentiment.allCases) { tier in
                    let rows = filtered.filter { $0.sentiment == tier }
                    if !rows.isEmpty {
                        Section {
                            ForEach(rows) { r in rowLink(r) }
                        } header: {
                            tierHeader(tier, count: rows.count)
                        }
                    }
                }
            } else {
                Section {
                    ForEach(filtered) { r in rowLink(r) }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func rowLink(_ r: Restaurant) -> some View {
        NavigationLink {
            RestaurantDetailView(restaurant: r, allRestaurants: allRestaurants)
        } label: {
            RestaurantRow(restaurant: r,
                          rankNumber: rankLookup[r.id] ?? (r.rankIndex + 1),
                          score: scoreBook.score(r))
        }
        .listRowBackground(Theme.bg)
    }

    private func tierHeader(_ tier: Sentiment, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: tier.symbol)
                .foregroundStyle(tier.color)
            Text(tier.rawValue)
                .font(Theme.rounded(13, .bold))
                .foregroundStyle(Theme.ink)
            Text("·  \(count)")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
        }
        .textCase(nil)
    }

    private var addButton: some View {
        Button {
            showAdd = true
            Haptics.tap(settings.hapticsEnabled)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(Circle().fill(Theme.accent))
                .shadow(color: Theme.accent.opacity(0.35), radius: 8, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .accessibilityLabel("Add a restaurant")
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Sort", selection: $sort) {
                    ForEach(ListSort.allCases) { s in
                        Label(s.rawValue, systemImage: s.symbol).tag(s)
                    }
                }

                Menu("Cuisine") {
                    Button("All cuisines") { cuisineFilter = nil }
                    ForEach(availableCuisines) { c in
                        Button {
                            cuisineFilter = (cuisineFilter == c) ? nil : c
                        } label: {
                            Label(c.rawValue, systemImage: cuisineFilter == c ? "checkmark" : c.symbol)
                        }
                    }
                }

                Menu("City") {
                    Button("All cities") { cityFilter = nil }
                    ForEach(availableCities, id: \.self) { city in
                        Button {
                            cityFilter = (cityFilter == city) ? nil : city
                        } label: {
                            if cityFilter == city {
                                Label(city, systemImage: "checkmark")
                            } else {
                                Text(city)
                            }
                        }
                    }
                }

                Menu("Sentiment") {
                    Button("All") { sentimentFilter = nil }
                    ForEach(Sentiment.allCases) { s in
                        Button {
                            sentimentFilter = (sentimentFilter == s) ? nil : s
                        } label: {
                            Label(s.rawValue, systemImage: sentimentFilter == s ? "checkmark" : s.symbol)
                        }
                    }
                }

                if hasActiveFilter {
                    Divider()
                    Button(role: .destructive) { clearFilters() } label: {
                        Label("Clear filters", systemImage: "xmark.circle")
                    }
                }
            } label: {
                Image(systemName: hasActiveFilter ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
            }
            .accessibilityLabel("Sort and filter")
        }
    }

    private func clearFilters() {
        cuisineFilter = nil
        cityFilter = nil
        sentimentFilter = nil
        searchText = ""
    }
}
