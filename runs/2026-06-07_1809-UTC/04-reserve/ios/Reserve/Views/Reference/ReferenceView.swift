import SwiftUI

/// The Reference tab: a browsable appliance catalog grouped by category, plus a
/// short glossary of off-grid terms.
struct ReferenceView: View {
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
            ScrollView {
                LazyVStack(spacing: 18, pinnedViews: []) {
                    if search.isEmpty {
                        glossaryCard
                    }

                    if groups.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No matches",
                            message: "Nothing in the catalog matches \"\(search)\"."
                        )
                    } else {
                        ForEach(groups, id: \.category) { group in
                            categorySection(group.category, group.items)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Brand.pageBackground)
            .searchable(text: $search, prompt: "Search appliances")
            .navigationTitle("Reference")
        }
    }

    private func categorySection(_ category: LoadCategory, _ items: [CatalogAppliance]) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: category.icon)
                        .foregroundStyle(category.tint)
                        .accessibilityHidden(true)
                    SectionTitle(text: category.label)
                }
                ForEach(items) { item in
                    ReferenceRow(appliance: item)
                    if item.id != items.last?.id {
                        Divider().overlay(Brand.hairline)
                    }
                }
            }
        }
    }

    private var glossaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow(text: "Glossary")
                ForEach(GlossaryEntry.all) { entry in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.term)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Brand.text)
                        Text(entry.definition)
                            .font(.caption)
                            .foregroundStyle(Brand.text2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if entry.id != GlossaryEntry.all.last?.id {
                        Divider().overlay(Brand.hairline)
                    }
                }
            }
        }
    }
}

private struct ReferenceRow: View {
    let appliance: CatalogAppliance
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(appliance.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text)
                Text("\(Fmt.dec1(appliance.typicalHoursPerDay)) h/day · \(Fmt.wh(appliance.watts * appliance.typicalHoursPerDay)) typical")
                    .font(Brand.mono(11))
                    .foregroundStyle(Brand.text3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(Fmt.watts(appliance.watts))
                    .font(Brand.mono(14, weight: .semibold))
                    .foregroundStyle(Brand.text)
                Badge(text: appliance.isAC ? "AC" : "DC", color: appliance.isAC ? Brand.danger : Brand.info)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(appliance.name), \(Fmt.watts(appliance.watts)), \(appliance.isAC ? "AC" : "DC"), \(Fmt.dec1(appliance.typicalHoursPerDay)) hours per day")
    }
}

private struct GlossaryEntry: Identifiable {
    let id = UUID()
    let term: String
    let definition: String

    static let all: [GlossaryEntry] = [
        GlossaryEntry(
            term: "Depth of Discharge (DoD)",
            definition: "How much of a battery's rated capacity you can safely use. LiFePO4 tolerates ~90%; flooded lead nearer 50%."
        ),
        GlossaryEntry(
            term: "Peak Sun Hours",
            definition: "Daily solar energy expressed as hours of full-strength sun. A panel makes its rated watts during each peak hour."
        ),
        GlossaryEntry(
            term: "Solar Derate",
            definition: "A realism factor (~75%) for wiring loss, heat, dust, panel angle and controller inefficiency."
        ),
        GlossaryEntry(
            term: "Charge Efficiency",
            definition: "Energy that actually lands in the battery versus what the charger sends — typically 80–90%."
        ),
        GlossaryEntry(
            term: "Watt-hours vs. Amp-hours",
            definition: "Wh measures true energy. Ah depends on voltage: Wh = Ah × volts. Compare banks of different voltages in Wh."
        ),
        GlossaryEntry(
            term: "Days of Autonomy",
            definition: "How long the usable bank lasts with no charging at your daily draw — your cloudy-day cushion."
        )
    ]
}

#Preview {
    ReferenceView()
}
