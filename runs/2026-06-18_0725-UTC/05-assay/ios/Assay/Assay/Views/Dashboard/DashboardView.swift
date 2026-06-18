import SwiftUI
import SwiftData

/// Home screen: latest panel summary, out-of-range alerts, recently changed
/// markers, and a CTA to log new results.
struct DashboardView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Query private var results: [LabResult]

    @State private var showLog = false
    @State private var showSettings = false
    @State private var selectedMarkerId: String?

    private var sex: BiologicalSex { settings.biologicalSex }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Assay")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showLog) { LogPanelSheet() }
            .navigationDestination(item: $selectedMarkerId) { id in
                if let marker = BiomarkerCatalog.marker(id) {
                    MarkerDetailView(marker: marker)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if results.isEmpty {
            EmptyStateView(
                icon: "drop.fill",
                title: "No results yet",
                message: "Log your first lab panel to see your markers scored against reference and optimal ranges.",
                ctaTitle: "Log a panel",
                action: { showLog = true }
            )
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    alertsCard
                    recentlyChangedCard
                    logCTA
                }
                .padding(16)
            }
        }
    }

    // MARK: - Summary

    private var latestPanel: Panel? { LabAnalytics.latestPanel(from: results) }

    private var summary: PanelSummary? {
        guard let p = latestPanel else { return nil }
        return StatsEngine.summarize(panelResults: p.results, sex: sex)
    }

    @ViewBuilder
    private var summaryCard: some View {
        if let s = summary, let p = latestPanel {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Latest panel")
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                        Text(Fmt.date(p.drawDate))
                            .font(Theme.rounded(18, .bold))
                            .foregroundStyle(Theme.ink)
                        Text(p.labName.isEmpty ? "\(s.resultCount) markers" : "\(p.labName) · \(s.resultCount) markers")
                            .font(.footnote)
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    scorePill(s.score)
                }

                HStack(spacing: 18) {
                    InRangeDonut(optimal: s.optimalCount, inRange: s.inRangeCount, outOfRange: s.outOfRangeCount)
                        .frame(width: 130, height: 130)

                    VStack(alignment: .leading, spacing: 10) {
                        legendRow(color: Theme.good, label: "Optimal", count: s.optimalCount)
                        legendRow(color: Theme.okay, label: "In range", count: s.inRangeCount)
                        legendRow(color: Theme.bad, label: "Out of range", count: s.outOfRangeCount)
                    }
                    Spacer()
                }
            }
            .assayCard()
        }
    }

    private func scorePill(_ score: Int) -> some View {
        VStack(spacing: 0) {
            Text("\(score)")
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.accent)
            Text("score")
                .font(Theme.rounded(11, .semibold))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(12)
        .background(Theme.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Panel score")
        .accessibilityValue("\(score) out of 100")
    }

    private func legendRow(color: Color, label: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(.subheadline).foregroundStyle(Theme.ink)
            Spacer(minLength: 6)
            Text("\(count)").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
        }
    }

    // MARK: - Alerts

    private var outOfRangeSnapshots: [MarkerSnapshot] {
        LabAnalytics.latestSnapshots(from: results, sex: sex)
            .filter { $0.assessment.status.isOutOfRange }
            .sorted { $0.assessment.severity > $1.assessment.severity }
    }

    @ViewBuilder
    private var alertsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "exclamationmark.triangle.fill", title: "Out of range", tint: Theme.bad)
            if outOfRangeSnapshots.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.good)
                    Text("Every tracked marker is within its standard range. Nice.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(.vertical, 4)
            } else {
                ForEach(outOfRangeSnapshots) { snap in
                    Button {
                        selectedMarkerId = snap.marker.id
                    } label: {
                        markerRow(snap)
                    }
                    .buttonStyle(.plain)
                    if snap.id != outOfRangeSnapshots.last?.id {
                        Divider().background(Theme.hairline)
                    }
                }
            }
        }
        .assayCard()
    }

    private func markerRow(_ snap: MarkerSnapshot) -> some View {
        let altUnit = settings.preferredAltUnit(for: snap.marker)
        let display = UnitConverter.display(canonical: snap.assessment.canonicalValue, altUnit: altUnit)
        let unit = altUnit?.unit ?? snap.marker.unit
        return HStack(spacing: 12) {
            Image(systemName: snap.marker.category.safeSymbol)
                .font(.system(size: 15))
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(snap.marker.name)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(Fmt.value(display)) \(unit)")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            StatusChip(status: snap.assessment.status, compact: true)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    // MARK: - Recently changed

    private struct ChangedMarker: Identifiable {
        let snapshot: MarkerSnapshot
        let trend: MarkerTrend
        var id: String { snapshot.id }
    }

    private var recentlyChanged: [ChangedMarker] {
        let snaps = LabAnalytics.latestSnapshots(from: results, sex: sex)
        var out: [ChangedMarker] = []
        for snap in snaps {
            let samples = LabAnalytics.samples(for: snap.marker.id, results: results)
            let mid = LabAnalytics.optimalMid(for: snap.marker, sex: sex)
            guard let trend = TrendEngine.trend(for: samples, goodDirection: snap.marker.direction, optimalMid: mid),
                  trend.pointCount >= 2 else { continue }
            out.append(ChangedMarker(snapshot: snap, trend: trend))
        }
        return out
            .sorted { abs($0.trend.percentChange ?? 0) > abs($1.trend.percentChange ?? 0) }
            .prefix(5)
            .map { $0 }
    }

    @ViewBuilder
    private var recentlyChangedCard: some View {
        let items = recentlyChanged
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(icon: "arrow.up.arrow.down.circle.fill", title: "Recently changed", tint: Theme.accent)
                ForEach(items) { item in
                    Button {
                        selectedMarkerId = item.snapshot.marker.id
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.snapshot.marker.category.safeSymbol)
                                .font(.system(size: 15))
                                .foregroundStyle(Theme.accent)
                                .frame(width: 28)
                                .accessibilityHidden(true)
                            Text(item.snapshot.marker.name)
                                .font(Theme.rounded(15, .semibold))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            TrendBadge(trend: item.trend)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.inkFaint)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if item.id != items.last?.id {
                        Divider().background(Theme.hairline)
                    }
                }
            }
            .assayCard()
        }
    }

    // MARK: - CTA

    private var logCTA: some View {
        Button {
            Haptics.impact(.light, enabled: settings.hapticsEnabled)
            showLog = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Log a new panel")
                    .font(Theme.rounded(16, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Theme.heroGradient)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func sectionHeader(icon: String, title: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
        }
    }
}
