import SwiftUI
import SwiftData

struct LifeListView: View {
    @Query private var species: [Species]
    @State private var search = ""
    @State private var sort: SortMode = .taxonomic

    enum SortMode: String, CaseIterable { case taxonomic = "Checklist", alphabetical = "A–Z", recent = "Recent" }

    private var seen: [Species] {
        var list = species.filter { !$0.sightings.isEmpty }
        if !search.isEmpty {
            let q = search.lowercased()
            list = list.filter { $0.commonName.lowercased().contains(q) || $0.scientificName.lowercased().contains(q) }
        }
        switch sort {
        case .taxonomic: list.sort { $0.taxonOrder < $1.taxonOrder }
        case .alphabetical: list.sort { $0.commonName < $1.commonName }
        case .recent: list.sort { ($0.lastSeen ?? .distantPast) > ($1.lastSeen ?? .distantPast) }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            Group {
                if species.filter({ !$0.sightings.isEmpty }).isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "list.star", title: "Your life list awaits",
                                       message: "Log your first sighting on the Sightings tab and the species will appear here.")
                        .glassCard().padding()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            headerCard
                            ForEach(seen) { sp in
                                NavigationLink { SpeciesDetailView(species: sp) } label: {
                                    SpeciesRow(species: sp)
                                }
                                .buttonStyle(.plain)
                            }
                            if seen.isEmpty {
                                Text("No matches").font(.subheadline).foregroundStyle(Brand.text3).padding()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Life List")
            .searchable(text: $search, prompt: "Search species")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Sort", selection: $sort) {
                        ForEach(SortMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu).tint(Brand.text2)
                }
            }
            .background(Brand.pageBackground)
        }
    }

    private var headerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Life species").font(.caption).foregroundStyle(Brand.text3)
                Text("\(species.filter { !$0.sightings.isEmpty }.count)")
                    .font(Brand.mono(30, weight: .bold)).foregroundStyle(Brand.text)
            }
            Spacer()
            StatusDot()
            Text("\(Set(species.filter { !$0.sightings.isEmpty }.map(\.family)).count) families")
                .font(.caption).foregroundStyle(Brand.text2)
        }
        .glassCard()
    }
}

struct SpeciesRow: View {
    let species: Species
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(species.commonName).font(.body.weight(.medium)).foregroundStyle(Brand.text)
                Text(species.scientificName).font(.caption).italic().foregroundStyle(Brand.text3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("×\(species.sightingCount)").font(Brand.mono(13, weight: .semibold)).foregroundStyle(Brand.text2)
                if let f = species.firstSeen {
                    Text(f, format: .dateTime.month(.abbreviated).year())
                        .font(.caption2).foregroundStyle(Brand.text3)
                }
            }
        }
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(species.commonName), seen \(species.sightingCount) times")
    }
}
