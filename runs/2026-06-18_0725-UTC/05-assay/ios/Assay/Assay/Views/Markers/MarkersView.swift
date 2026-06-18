import SwiftUI
import SwiftData

/// Browse the biomarker catalog by category, with search → marker detail.
struct MarkersView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query private var results: [LabResult]
    @State private var search = ""

    private var sex: BiologicalSex { settings.biologicalSex }

    private var trackedIds: Set<String> {
        LabAnalytics.trackedMarkerIds(from: results)
    }

    private var filtered: [Biomarker] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return BiomarkerCatalog.all }
        return BiomarkerCatalog.all.filter {
            $0.name.lowercased().contains(q) ||
            $0.shortName.lowercased().contains(q) ||
            $0.category.rawValue.lowercased().contains(q)
        }
    }

    private var grouped: [(category: MarkerCategory, markers: [Biomarker])] {
        MarkerCategory.allCases.compactMap { cat in
            let ms = filtered.filter { $0.category == cat }
            return ms.isEmpty ? nil : (cat, ms)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if grouped.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No matches",
                        message: "No markers match \"\(search)\". Try a different name or category."
                    )
                } else {
                    List {
                        ForEach(grouped, id: \.category.id) { group in
                            Section {
                                ForEach(group.markers) { marker in
                                    NavigationLink {
                                        MarkerDetailView(marker: marker)
                                    } label: {
                                        catalogRow(marker)
                                    }
                                    .listRowBackground(Theme.surface)
                                }
                            } header: {
                                Label(group.category.rawValue, systemImage: group.category.safeSymbol)
                                    .font(Theme.rounded(14, .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Markers")
            .searchable(text: $search, prompt: "Search markers")
        }
    }

    private func catalogRow(_ marker: Biomarker) -> some View {
        let snapshot = latestSnapshot(for: marker)
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(marker.name)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(referenceText(marker))
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            if let snap = snapshot {
                StatusChip(status: snap.assessment.status, compact: true)
            } else if trackedIds.contains(marker.id) == false {
                Text("Not logged")
                    .font(.caption2)
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(.vertical, 3)
    }

    private func latestSnapshot(for marker: Biomarker) -> MarkerSnapshot? {
        let snaps = LabAnalytics.latestSnapshots(from: results, sex: sex)
        return snaps.first { $0.marker.id == marker.id }
    }

    private func referenceText(_ marker: Biomarker) -> String {
        let r = marker.standard.range(for: sex)
        let unit = marker.unit
        switch (r.low, r.high) {
        case let (lo?, hi?): return "Ref \(Fmt.value(lo))–\(Fmt.value(hi)) \(unit)"
        case let (lo?, nil): return "Ref ≥ \(Fmt.value(lo)) \(unit)"
        case let (nil, hi?): return "Ref ≤ \(Fmt.value(hi)) \(unit)"
        case (nil, nil): return marker.unit
        }
    }
}
