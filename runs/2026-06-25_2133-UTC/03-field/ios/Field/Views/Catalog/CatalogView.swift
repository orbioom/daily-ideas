import SwiftUI
import SwiftData

struct CatalogView: View {
    @Query(sort: \Observation.speciesName) private var observations: [Observation]
    @State private var searchText = ""
    @State private var classFilter: SpeciesClass?
    @State private var showLifersOnly = false

    private var speciesList: [SpeciesEntry] {
        var dict: [String: (Observation, Int)] = [:]
        for o in observations {
            let key = o.speciesName.lowercased()
            if let existing = dict[key] {
                dict[key] = (existing.0, existing.1 + 1)
            } else {
                dict[key] = (o, 1)
            }
        }
        var list = dict.values.map { SpeciesEntry(obs: $0.0, count: $0.1) }
        if let c = classFilter { list = list.filter { $0.obs.speciesClass == c } }
        if showLifersOnly { list = list.filter { $0.obs.isLifer } }
        if !searchText.isEmpty {
            let lower = searchText.lowercased()
            list = list.filter {
                $0.obs.speciesName.lowercased().contains(lower) ||
                $0.obs.commonName.lowercased().contains(lower)
            }
        }
        return list.sorted { $0.obs.displayName < $1.obs.displayName }
    }

    var body: some View {
        NavigationStack {
            Group {
                if observations.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        filterRow
                        speciesListView
                    }
                }
            }
            .navigationTitle("Catalog")
            .searchable(text: $searchText, prompt: "Search species")
            .navigationDestination(for: Observation.self) { obs in
                ObservationDetailView(observation: obs)
            }
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Toggle("Lifers", isOn: $showLifersOnly)
                    .toggleStyle(.button)
                    .tint(FieldTheme.fern)
                    .font(.caption.weight(.semibold))

                Divider().frame(height: 20)

                Button("All") { classFilter = nil }
                    .fieldChip2(isSelected: classFilter == nil)

                ForEach(SpeciesClass.allCases) { sc in
                    Button(sc.emoji) { classFilter = sc }
                        .fieldChip2(isSelected: classFilter == sc, color: sc.color)
                        .accessibilityLabel(sc.rawValue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var speciesListView: some View {
        List {
            Section {
                ForEach(speciesList) { entry in
                    NavigationLink(value: entry.obs) {
                        HStack(spacing: 12) {
                            Text(entry.obs.speciesClass.emoji).font(.title3).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(entry.obs.displayName).font(.subheadline.bold())
                                    if entry.obs.isLifer { LiferBadge() }
                                }
                                if !entry.obs.speciesName.isEmpty && entry.obs.speciesName != entry.obs.commonName {
                                    Text(entry.obs.speciesName)
                                        .font(.caption.italic())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text("×\(entry.count)")
                                .font(.caption.bold())
                                .foregroundStyle(FieldTheme.fern)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(entry.obs.displayName), observed \(entry.count) time\(entry.count == 1 ? "" : "s")\(entry.obs.isLifer ? ", lifer" : "")")
                    }
                }
            } header: {
                Text("\(speciesList.count) species")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 56))
                .foregroundStyle(FieldTheme.fern.opacity(0.5))
                .accessibilityHidden(true)
            Text("Catalog is empty")
                .font(.title3.bold())
            Text("All distinct species you observe will appear here.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SpeciesEntry: Identifiable {
    let id: UUID
    let obs: Observation
    let count: Int

    init(obs: Observation, count: Int) {
        self.id = obs.id
        self.obs = obs
        self.count = count
    }
}

private extension View {
    func fieldChip2(isSelected: Bool, color: Color = FieldTheme.fern) -> some View {
        self
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? color : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
    }
}
