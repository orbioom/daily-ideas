import SwiftUI

/// A searchable list of catalog stores for one-tap quick-add. Picking a store inserts
/// a card (with an empty code the user fills in on the detail / edit screen) and dismisses.
struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    let onPick: (CatalogStore) -> Void

    private var filtered: [CatalogStore] {
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !term.isEmpty else { return StoreCatalog.all }
        return StoreCatalog.all.filter {
            $0.name.lowercased().contains(term) || $0.category.displayName.lowercased().contains(term)
        }
    }

    private var grouped: [(category: CardCategory, stores: [CatalogStore])] {
        let dict = Dictionary(grouping: filtered, by: { $0.category })
        return CardCategory.allCases.compactMap { category in
            guard let stores = dict[category], !stores.isEmpty else { return nil }
            return (category, stores.sorted { $0.name < $1.name })
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    EmptyStateView(symbol: "magnifyingglass",
                                   title: "No stores found",
                                   message: "No catalog store matches “\(search)”. You can add a custom card instead.")
                } else {
                    List {
                        ForEach(grouped, id: \.category) { group in
                            Section(group.category.displayName) {
                                ForEach(group.stores) { store in
                                    Button {
                                        onPick(store)
                                        dismiss()
                                    } label: {
                                        row(store)
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Theme.bg.ignoresSafeArea())
                }
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Search stores")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func row(_ store: CatalogStore) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hexString: store.colorHex, fallback: Theme.accent))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: store.category.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hexString: store.colorHex, fallback: Theme.accent).readableForeground)
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.name)
                    .font(Theme.rounded(16, .medium))
                    .foregroundStyle(Theme.ink)
                Text(store.suggestedFormat.displayName)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Add \(store.name)")
    }
}
