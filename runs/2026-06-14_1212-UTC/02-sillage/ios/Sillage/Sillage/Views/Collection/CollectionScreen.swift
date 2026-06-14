import SwiftUI
import SwiftData

/// The owned collection: a juice-swatch grid with search, filter, and sort.
struct CollectionScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Fragrance.addedAt, order: .reverse) private var allFragrances: [Fragrance]

    @State private var searchText = ""
    @State private var sort: CollectionSort = .added
    @State private var houseFilter: String?
    @State private var concentrationFilter: Concentration?
    @State private var seasonFilter: Season?
    @State private var showAdd = false
    @State private var paywallReason: PaywallReason?
    @State private var didSetDefaultSort = false

    /// Items shown here: owned + decant.
    private var collection: [Fragrance] {
        allFragrances.filter { $0.status.isInCollection }
    }

    private var availableHouses: [String] {
        Array(Set(collection.map { $0.house.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty })).sorted()
    }

    private var availableConcentrations: [Concentration] {
        Array(Set(collection.map { $0.concentration })).sorted { $0.weight < $1.weight }
    }

    private var hasActiveFilter: Bool {
        houseFilter != nil || concentrationFilter != nil || seasonFilter != nil
    }

    private var filtered: [Fragrance] {
        var list = collection
        if let houseFilter { list = list.filter { $0.house.trimmingCharacters(in: .whitespaces) == houseFilter } }
        if let concentrationFilter { list = list.filter { $0.concentration == concentrationFilter } }
        if let seasonFilter { list = list.filter { $0.seasons.contains(seasonFilter) } }

        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.name.lowercased().contains(q) ||
                $0.house.lowercased().contains(q) ||
                $0.placements.contains { p in p.displayName.lowercased().contains(q) }
            }
        }

        switch sort {
        case .added: list.sort { $0.addedAt > $1.addedAt }
        case .mostWorn: list.sort { $0.timesWorn > $1.timesWorn }
        case .costPerWear:
            list.sort { lhs, rhs in
                // Bottles with a price first, cheapest-per-wear first; priceless last.
                switch (lhs.pricePaid > 0, rhs.pricePaid > 0) {
                case (true, true): return lhs.costPerWear < rhs.costPerWear
                case (true, false): return true
                case (false, true): return false
                case (false, false): return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
            }
        case .rating: list.sort { $0.rating > $1.rating }
        case .name: list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        return list
    }

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Theme.bg.ignoresSafeArea()
                content
                addButton
            }
            .navigationTitle("Collection")
            .toolbar { toolbarContent }
            .searchable(text: $searchText, prompt: "Search name, house, note")
            .sheet(isPresented: $showAdd) {
                FragranceEditorView(defaultStatus: .owned)
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
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
        if collection.isEmpty {
            EmptyStateView(symbol: "square.grid.2x2",
                           title: "Your shelf is empty",
                           message: "Add your first bottle — its house, concentration, and note pyramid — and Sillage starts your private collection.",
                           actionTitle: "Add a fragrance") { startAdd() }
        } else if filtered.isEmpty {
            EmptyStateView(symbol: "magnifyingglass",
                           title: "No matches",
                           message: "Nothing fits those filters. Try clearing them or searching differently.",
                           actionTitle: "Clear filters") { clearFilters() }
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(filtered) { f in
                        NavigationLink {
                            FragranceDetailView(fragrance: f)
                        } label: {
                            FragranceCard(fragrance: f, costPerWear: costPerWearLabel(f))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 90)
            }
        }
    }

    private func costPerWearLabel(_ f: Fragrance) -> String? {
        guard sort == .costPerWear, !settings.hidePrices, f.pricePaid > 0 else { return nil }
        return "\(settings.formatMoney(f.costPerWear)) / wear"
    }

    private var addButton: some View {
        Button {
            startAdd()
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
        .accessibilityLabel("Add a fragrance")
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Sort", selection: $sort) {
                    ForEach(CollectionSort.allCases) { s in
                        Label(s.rawValue, systemImage: s.symbol).tag(s)
                    }
                }

                Menu("House") {
                    Button("All houses") { houseFilter = nil }
                    ForEach(availableHouses, id: \.self) { h in
                        Button {
                            houseFilter = (houseFilter == h) ? nil : h
                        } label: {
                            if houseFilter == h { Label(h, systemImage: "checkmark") } else { Text(h) }
                        }
                    }
                }

                Menu("Concentration") {
                    Button("All concentrations") { concentrationFilter = nil }
                    ForEach(availableConcentrations) { c in
                        Button {
                            concentrationFilter = (concentrationFilter == c) ? nil : c
                        } label: {
                            Label(c.rawValue, systemImage: concentrationFilter == c ? "checkmark" : "drop")
                        }
                    }
                }

                Menu("Season") {
                    Button("All seasons") { seasonFilter = nil }
                    ForEach(Season.allCases) { s in
                        Button {
                            seasonFilter = (seasonFilter == s) ? nil : s
                        } label: {
                            Label(s.rawValue, systemImage: seasonFilter == s ? "checkmark" : s.symbol)
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

    private func startAdd() {
        if Pro.canAdd(currentCount: allFragrances.count, isPro: isPro) {
            showAdd = true
            Haptics.tap(settings.hapticsEnabled)
        } else {
            paywallReason = .collectionLimit
            Haptics.warning(settings.hapticsEnabled)
        }
    }

    private func clearFilters() {
        houseFilter = nil
        concentrationFilter = nil
        seasonFilter = nil
        searchText = ""
    }
}
