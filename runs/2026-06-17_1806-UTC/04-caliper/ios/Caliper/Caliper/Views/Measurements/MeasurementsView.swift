import SwiftUI
import SwiftData

struct MeasurementsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var proStore: ProStore

    @Query(sort: \MeasurementSite.sortOrder) private var sites: [MeasurementSite]
    @Query(sort: \MeasurementEntry.date) private var entries: [MeasurementEntry]

    @State private var showPaywall = false

    private var entriesByKey: [String: [MeasurementEntry]] {
        Dictionary(grouping: entries, by: { $0.siteKey })
    }

    private func isLocked(_ site: MeasurementSite) -> Bool {
        !proStore.isPro && !ProGate.freeSiteKeys.contains(site.key)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(sites) { site in
                        row(for: site)
                    }
                } header: {
                    Text("Tracked sites")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }

                if !proStore.isPro {
                    Section {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(Theme.warn)
                                Text("Unlock all sites & custom sites with Pro")
                                    .font(Theme.rounded(15, .semibold))
                                    .foregroundStyle(Theme.ink)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Measurements")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    @ViewBuilder
    private func row(for site: MeasurementSite) -> some View {
        let locked = isLocked(site)
        let siteEntries = entriesByKey[site.key] ?? []
        let stats = SiteStats.compute(entries: siteEntries)
        let kind = site.unitKind
        let valueText = stats.current.map { Units.formatted(canonical: $0, kind: kind, system: settings.unitSystem) } ?? "—"
        let unit = Units.unitLabel(kind: kind, system: settings.unitSystem)
        let (changeText, intent) = changeLabel(stats: stats, kind: kind)

        if locked {
            Button {
                showPaywall = true
            } label: {
                SiteRow(name: site.name, icon: SiteCatalog.symbol(for: site.key),
                        valueText: valueText, unitText: unit,
                        changeText: changeText, intent: intent, locked: true)
            }
        } else {
            NavigationLink {
                SiteDetailView(site: site)
            } label: {
                SiteRow(name: site.name, icon: SiteCatalog.symbol(for: site.key),
                        valueText: valueText, unitText: unit,
                        changeText: changeText, intent: intent, locked: false)
            }
        }
    }

    private func changeLabel(stats: SiteStats, kind: UnitKind) -> (String?, ChangeIntent) {
        guard let change = stats.changeSincePrevious else { return (nil, .neutral) }
        let displayChange = Units.displayValue(canonical: abs(change), kind: kind, system: settings.unitSystem)
        let unit = Units.unitLabel(kind: kind, system: settings.unitSystem)
        let arrow = change > 0 ? "▲" : (change < 0 ? "▼" : "→")
        let intent: ChangeIntent = abs(change) < 0.0001 ? .neutral : (change < 0 ? .good : .bad)
        return ("\(arrow) \(Units.number(displayChange, digits: Units.fractionDigits(kind: kind))) \(unit)", intent)
    }
}
