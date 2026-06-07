import SwiftUI

/// A sheet that lets the user pick an appliance from the catalog (with a quantity)
/// to add to the current system.
struct CatalogPickerView: View {
    var onPick: (CatalogAppliance, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var groups: [(category: LoadCategory, items: [CatalogAppliance])] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return ApplianceCatalog.byCategory.compactMap { group in
            let items = query.isEmpty
                ? group.items
                : group.items.filter { $0.name.lowercased().contains(query) }
            return items.isEmpty ? nil : (group.category, items)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if groups.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No matches",
                        message: "Nothing in the catalog matches \"\(search)\"."
                    )
                } else {
                    List {
                        ForEach(groups, id: \.category) { group in
                            Section(group.category.label) {
                                ForEach(group.items) { appliance in
                                    CatalogPickRow(appliance: appliance) { qty in
                                        onPick(appliance, qty)
                                        Haptics.tap()
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Brand.pageBackground)
            .searchable(text: $search, prompt: "Search appliances")
            .navigationTitle("Add from Catalog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct CatalogPickRow: View {
    let appliance: CatalogAppliance
    var onAdd: (Int) -> Void

    @State private var quantity = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(appliance.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.text)
                    Text("\(Fmt.int(appliance.watts)) W · \(Fmt.dec1(appliance.typicalHoursPerDay)) h/day")
                        .font(Brand.mono(11))
                        .foregroundStyle(Brand.text3)
                }
                Spacer()
                Badge(text: appliance.isAC ? "AC" : "DC", color: appliance.isAC ? Brand.danger : Brand.info)
            }
            HStack {
                Stepper(value: $quantity, in: 1...20) {
                    Text("Qty \(quantity)")
                        .font(Brand.mono(12, weight: .medium))
                        .foregroundStyle(Brand.text2)
                }
                .fixedSize()
                Spacer()
                Button {
                    onAdd(quantity)
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .tint(Brand.magic)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.clear)
    }
}
