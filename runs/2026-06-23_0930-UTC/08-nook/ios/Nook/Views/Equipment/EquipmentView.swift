import SwiftUI
import SwiftData

struct EquipmentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Appliance.name) private var appliances: [Appliance]
    @Query private var settingsRows: [AppSettings]

    @State private var searchText = ""
    @State private var showingEditor = false
    @State private var selectedAppliance: Appliance?

    private var settings: AppSettings { settingsRows.first ?? AppSettings() }

    private var filtered: [Appliance] {
        guard !searchText.isEmpty else { return appliances }
        return appliances.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.brand.localizedCaseInsensitiveContains(searchText) ||
            $0.modelNumber.localizedCaseInsensitiveContains(searchText) ||
            $0.kind.label.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var expiringSoonCount: Int {
        appliances.filter {
            if case .expiringSoon = WarrantyEngine.status(for: $0) { return true }
            return false
        }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if appliances.isEmpty {
                    EmptyStateView(systemImage: "wrench.and.screwdriver",
                                   title: "No equipment yet",
                                   message: "Record your appliances and home systems with their model, purchase date and warranty.",
                                   actionTitle: "Add equipment") { showingEditor = true }
                } else if filtered.isEmpty {
                    EmptyStateView(systemImage: "magnifyingglass",
                                   title: "Nothing matches",
                                   message: "Try a different search term.")
                } else {
                    list
                }
            }
            .navigationTitle("Equipment")
            .background(Theme.bg.ignoresSafeArea())
            .searchable(text: $searchText, prompt: "Search by name, brand or model")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingEditor = true } label: { Label("Add equipment", systemImage: "plus") }
                }
            }
            .navigationDestination(item: $selectedAppliance) { ApplianceDetailView(appliance: $0) }
            .sheet(isPresented: $showingEditor) { ApplianceEditorView(appliance: nil) }
        }
    }

    private var list: some View {
        List {
            if expiringSoonCount > 0 && searchText.isEmpty {
                Section {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "exclamationmark.shield")
                            .foregroundStyle(Theme.due)
                            .accessibilityHidden(true)
                        Text("\(expiringSoonCount) warranty\(expiringSoonCount == 1 ? "" : "ies") expiring soon")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .listRowBackground(Theme.due.opacity(0.12))
                    .accessibilityElement(children: .combine)
                }
            }
            Section {
                ForEach(filtered) { appliance in
                    Button { selectedAppliance = appliance } label: {
                        ApplianceRow(appliance: appliance)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Theme.card)
                    .swipeActions {
                        Button(role: .destructive) {
                            context.delete(appliance)
                            try? context.save()
                            Haptics.warning(enabled: settings.hapticsEnabled)
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
    }
}

#Preview {
    EquipmentView()
        .previewModelContainer()
}
