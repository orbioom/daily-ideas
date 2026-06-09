import SwiftUI

/// A searchable multi-select country picker. Returns the chosen ISO codes via a
/// binding. Used when adding countries to a trip.
struct CountryPickerView: View {
    @Binding var selectedCodes: [String]
    @Environment(\.dismiss) private var dismiss

    @State private var search = ""
    @State private var working: Set<String>

    init(selectedCodes: Binding<[String]>) {
        _selectedCodes = selectedCodes
        _working = State(initialValue: Set(selectedCodes.wrappedValue.map { $0.uppercased() }))
    }

    private var groups: [(continent: Continent, countries: [Country])] {
        CountryData.byContinent.compactMap { group in
            let countries = group.countries.filter { matchesSearch($0) }
            return countries.isEmpty ? nil : (group.continent, countries)
        }
    }

    private func matchesSearch(_ country: Country) -> Bool {
        guard !search.isEmpty else { return true }
        let q = search.lowercased()
        return country.name.lowercased().contains(q) || country.capital.lowercased().contains(q)
    }

    var body: some View {
        NavigationStack {
            List {
                if groups.isEmpty {
                    EmptyStateView(icon: "magnifyingglass",
                                   title: "No matches",
                                   message: "Try a different search.")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(groups, id: \.continent) { group in
                        Section(group.continent.label) {
                            ForEach(group.countries) { country in
                                Button {
                                    toggle(country.code)
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(country.flagEmoji)
                                            .font(.system(size: 26))
                                            .accessibilityHidden(true)
                                        Text(country.name)
                                            .foregroundStyle(Brand.text)
                                        Spacer()
                                        if working.contains(country.code) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Brand.magic)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                                .accessibilityLabel(country.name)
                                .accessibilityAddTraits(working.contains(country.code) ? [.isSelected] : [])
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Add countries")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Search countries")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { commit() }.fontWeight(.semibold)
                }
            }
        }
    }

    private func toggle(_ code: String) {
        Haptics.selection()
        if working.contains(code) { working.remove(code) } else { working.insert(code) }
    }

    private func commit() {
        // Preserve any prior order, then append newly added codes in dataset order.
        var ordered = selectedCodes.map { $0.uppercased() }.filter { working.contains($0) }
        for country in CountryData.all where working.contains(country.code) && !ordered.contains(country.code) {
            ordered.append(country.code)
        }
        selectedCodes = ordered
        dismiss()
    }
}
