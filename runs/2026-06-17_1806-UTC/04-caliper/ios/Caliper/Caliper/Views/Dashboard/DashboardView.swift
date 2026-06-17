import SwiftUI
import SwiftData

struct DashboardView: View {
    @Binding var selectedTab: Int
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var proStore: ProStore

    @Query(sort: \MeasurementSite.sortOrder) private var sites: [MeasurementSite]
    @Query(sort: \MeasurementEntry.date) private var entries: [MeasurementEntry]

    @State private var showLog = false

    /// Entries grouped by site key for quick stats.
    private var entriesByKey: [String: [MeasurementEntry]] {
        Dictionary(grouping: entries, by: { $0.siteKey })
    }

    private var hasAnyData: Bool { !entries.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                if hasAnyData {
                    content
                        .padding(.horizontal, 16)
                        .padding(.bottom, 28)
                } else {
                    EmptyStateView(
                        icon: "square.grid.2x2",
                        title: "No measurements yet",
                        message: "Log your first session to start seeing trends, computed metrics and goal progress here.",
                        actionTitle: "Log measurements",
                        action: { selectedTab = 2 }
                    )
                    .padding(.top, 60)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showLog) {
                LogSessionView()
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 18) {
            logButton

            // Core metric cards.
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(coreCards) { card in
                    MetricCard(
                        title: card.title,
                        icon: card.icon,
                        valueText: card.valueText,
                        unitText: card.unitText,
                        changeText: card.changeText,
                        intent: card.intent,
                        sparkValues: card.spark
                    )
                }
            }

            // Computed metrics.
            sectionHeader("Computed")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(computedCards) { card in
                    ComputedMetricCard(card: card)
                }
            }

            // Goal progress.
            if !goalSites.isEmpty {
                sectionHeader("Goals")
                ForEach(goalSites, id: \.key) { site in
                    if let bar = goalBar(for: site) {
                        bar
                    }
                }
            }
        }
    }

    private var logButton: some View {
        Button {
            Haptics.impact(.light, enabled: settings.hapticsEnabled)
            showLog = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                Text("Log measurements")
                    .font(Theme.rounded(17, .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        }
        .accessibilityHint("Opens the logging form to record a new measurement session")
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(18, .bold))
            .foregroundStyle(Theme.ink)
            .padding(.top, 4)
    }

    // MARK: Core cards

    private var coreCards: [DashboardCard] {
        let keys = ["weight", "bodyfat", "waist"]
        return keys.compactMap { key -> DashboardCard? in
            guard let site = sites.first(where: { $0.key == key }) else { return nil }
            let siteEntries = entriesByKey[key] ?? []
            let stats = SiteStats.compute(entries: siteEntries)
            guard let current = stats.current else { return nil }
            let kind = site.unitKind
            let valueText = Units.formatted(canonical: current, kind: kind, system: settings.unitSystem)
            let unit = Units.unitLabel(kind: kind, system: settings.unitSystem)
            let (changeText, intent) = changeLabel(stats: stats, kind: kind, lowerIsBetter: true)
            let spark = siteEntries.suffix(12).map {
                Units.displayValue(canonical: $0.valueCanonical, kind: kind, system: settings.unitSystem)
            }
            return DashboardCard(
                title: site.name, icon: SiteCatalog.symbol(for: key),
                valueText: valueText, unitText: unit,
                changeText: changeText, intent: intent, spark: spark
            )
        }
    }

    private func changeLabel(stats: SiteStats, kind: UnitKind, lowerIsBetter: Bool) -> (String?, ChangeIntent) {
        guard let change = stats.changeSincePrevious else { return (nil, .neutral) }
        let displayChange = Units.displayValue(canonical: abs(change), kind: kind, system: settings.unitSystem)
        let unit = Units.unitLabel(kind: kind, system: settings.unitSystem)
        let arrow = change > 0 ? "▲" : (change < 0 ? "▼" : "→")
        let text = "\(arrow) \(Units.number(displayChange, digits: Units.fractionDigits(kind: kind))) \(unit) since last"
        let intent: ChangeIntent
        if abs(change) < 0.0001 {
            intent = .neutral
        } else if (change < 0) == lowerIsBetter {
            intent = .good
        } else {
            intent = .bad
        }
        return (text, intent)
    }

    // MARK: Computed cards

    private func latest(_ key: String) -> Double? {
        entriesByKey[key]?.max(by: { $0.date < $1.date })?.valueCanonical
    }

    private var computedCards: [ComputedCard] {
        var cards: [ComputedCard] = []

        // BMI
        if let w = latest("weight"), let bmi = BodyMath.bmi(weightKg: w, heightCm: settings.heightCm) {
            cards.append(ComputedCard(
                title: "BMI", icon: "figure",
                value: Units.number(bmi, digits: 1),
                caption: BodyMath.bmiCategory(bmi),
                proOnly: false
            ))
        }
        // Waist-to-hip
        if let waist = latest("waist"), let hip = latest("hips"),
           let whr = BodyMath.waistToHip(waistCm: waist, hipCm: hip) {
            cards.append(ComputedCard(
                title: "Waist : Hip", icon: "circle.dashed",
                value: Units.number(whr, digits: 2),
                caption: BodyMath.waistToHipCategory(whr, sex: settings.biologicalSex),
                proOnly: false
            ))
        }
        // FFMI (Pro)
        if let w = latest("weight"), let bf = latest("bodyfat"),
           let ffmi = BodyMath.ffmi(weightKg: w, bodyFatPercent: bf, heightCm: settings.heightCm) {
            cards.append(ComputedCard(
                title: "FFMI", icon: "bolt.fill",
                value: proStore.isPro ? Units.number(ffmi.normalized, digits: 1) : "Pro",
                caption: proStore.isPro ? "Normalized" : "Unlock in Pro",
                proOnly: true
            ))
        }
        return cards
    }

    // MARK: Goals

    private var goalSites: [MeasurementSite] {
        sites.filter { $0.goalValue != nil && !(entriesByKey[$0.key] ?? []).isEmpty }
    }

    private func goalBar(for site: MeasurementSite) -> GoalProgressBar? {
        guard let goal = site.goalValue else { return nil }
        let siteEntries = (entriesByKey[site.key] ?? []).sorted { $0.date < $1.date }
        guard let first = siteEntries.first?.valueCanonical,
              let current = siteEntries.last?.valueCanonical else { return nil }
        let frac = GoalProgress.fraction(start: first, current: current, goal: goal)
        let goalText = Units.formatted(canonical: goal, kind: site.unitKind, system: settings.unitSystem)
        let curText = Units.formatted(canonical: current, kind: site.unitKind, system: settings.unitSystem)
        let unit = Units.unitLabel(kind: site.unitKind, system: settings.unitSystem)
        return GoalProgressBar(
            title: site.name,
            progress: frac,
            detail: "\(curText) → goal \(goalText) \(unit)"
        )
    }
}

struct DashboardCard: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let valueText: String
    let unitText: String
    let changeText: String?
    let intent: ChangeIntent
    let spark: [Double]
}

struct ComputedCard: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let value: String
    let caption: String
    let proOnly: Bool
}

private struct ComputedMetricCard: View {
    let card: ComputedCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: card.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(card.title)
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Spacer(minLength: 0)
                if card.proOnly {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.warn)
                        .accessibilityHidden(true)
                }
            }
            Text(card.value)
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(card.caption)
                .font(Theme.rounded(12, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(card.title)
        .accessibilityValue("\(card.value), \(card.caption)")
    }
}
