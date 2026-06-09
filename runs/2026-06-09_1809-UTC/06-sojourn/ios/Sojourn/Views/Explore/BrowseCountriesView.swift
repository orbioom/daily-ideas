import SwiftUI
import SwiftData

/// A pushable, searchable country browser without its own NavigationStack — used
/// as a destination (e.g. from the Passport empty state) so it inherits the
/// surrounding navigation. Tapping a country opens the editor sheet.
struct BrowseCountriesView: View {
    @Query private var marks: [VisitMark]

    @State private var search = ""
    @State private var selected: Country?

    private var statusByCode: [String: VisitStatus] {
        Dictionary(marks.map { ($0.countryCode, $0.status) }, uniquingKeysWith: { a, _ in a })
    }
    private var favoriteCodes: Set<String> {
        Set(marks.filter { $0.isFavorite }.map { $0.countryCode })
    }

    private func matchesSearch(_ country: Country) -> Bool {
        guard !search.isEmpty else { return true }
        let q = search.lowercased()
        return country.name.lowercased().contains(q) || country.capital.lowercased().contains(q)
    }

    private var groups: [(continent: Continent, countries: [Country])] {
        CountryData.byContinent.compactMap { group in
            let countries = group.countries.filter { matchesSearch($0) }
            return countries.isEmpty ? nil : (group.continent, countries)
        }
    }

    var body: some View {
        List {
            if groups.isEmpty {
                EmptyStateView(icon: "magnifyingglass",
                               title: "No countries match",
                               message: "Try a different search.")
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
        .navigationTitle("Mark a country")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, prompt: "Search countries")
        .sheet(item: $selected) { CountryDetailView(country: $0) }
    }
}
