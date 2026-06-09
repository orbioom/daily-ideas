import SwiftUI
import SwiftData

struct ExploreView: View {
    @Query private var marks: [VisitMark]

    @State private var search = ""
    @State private var filter: StatusFilter = .all
    @State private var selected: Country?

    /// Filter chips: All, or a specific status, plus "Unmarked".
    private enum StatusFilter: Hashable, Identifiable {
        case all, status(VisitStatus), unmarked
        var id: String {
            switch self {
            case .all: return "all"
            case .status(let s): return s.rawValue
            case .unmarked: return "unmarked"
            }
        }
        var label: String {
            switch self {
            case .all: return "All"
            case .status(let s): return s.label
            case .unmarked: return "Unmarked"
            }
        }
        static let allCases: [StatusFilter] =
            [.all] + VisitStatus.allCases.map { .status($0) } + [.unmarked]
    }

    /// code → status lookup for fast row decoration.
    private var statusByCode: [String: VisitStatus] {
        Dictionary(marks.map { ($0.countryCode, $0.status) }, uniquingKeysWith: { a, _ in a })
    }
    private var favoriteCodes: Set<String> {
        Set(marks.filter { $0.isFavorite }.map { $0.countryCode })
    }

    var body: some View {
        NavigationStack {
            List {
                let groups = filteredGroups
                if groups.isEmpty {
                    EmptyStateView(icon: "magnifyingglass",
                                   title: "No countries match",
                                   message: "Try a different search or filter.")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(groups, id: \.continent) { group in
                        Section(group.continent.label) {
                            ForEach(group.countries) { country in
                                Button {
                                    Haptics.tap()
                                    selected = country
                                } label: {
                                    CountryRow(country: country,
                                               status: statusByCode[country.code],
                                               isFavorite: favoriteCodes.contains(country.code))
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Explore")
            .searchable(text: $search, prompt: "Search countries")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterMenu
                }
            }
            .sheet(item: $selected) { country in
                CountryDetailView(country: country)
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            Picker("Filter", selection: $filter) {
                ForEach(StatusFilter.allCases) { f in
                    Text(f.label).tag(f)
                }
            }
        } label: {
            Label("Filter", systemImage: filter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
        }
    }

    // MARK: Filtering

    private func matchesFilter(_ code: String) -> Bool {
        switch filter {
        case .all: return true
        case .unmarked: return statusByCode[code] == nil
        case .status(let s): return statusByCode[code] == s
        }
    }

    private func matchesSearch(_ country: Country) -> Bool {
        guard !search.isEmpty else { return true }
        let q = search.lowercased()
        return country.name.lowercased().contains(q)
            || country.capital.lowercased().contains(q)
            || country.region.lowercased().contains(q)
    }

    private var filteredGroups: [(continent: Continent, countries: [Country])] {
        CountryData.byContinent.compactMap { group in
            let countries = group.countries.filter { matchesFilter($0.code) && matchesSearch($0) }
            return countries.isEmpty ? nil : (group.continent, countries)
        }
    }
}
