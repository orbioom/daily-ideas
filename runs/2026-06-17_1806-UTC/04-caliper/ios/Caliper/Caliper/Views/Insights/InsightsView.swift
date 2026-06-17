import SwiftUI
import SwiftData
import Charts

enum InsightWindow: Int, CaseIterable, Identifiable {
    case days30 = 30
    case days90 = 90
    case days365 = 365
    case all = 0

    var id: Int { rawValue }
    var label: String {
        switch self {
        case .days30: return "30d"
        case .days90: return "90d"
        case .days365: return "1y"
        case .all: return "All"
        }
    }
    var proOnly: Bool { self != .days30 }
}

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var proStore: ProStore

    @Query(sort: \MeasurementSite.sortOrder) private var sites: [MeasurementSite]
    @Query(sort: \MeasurementEntry.date) private var entries: [MeasurementEntry]

    @State private var window: InsightWindow = .days30
    @State private var isComputing = false
    @State private var summary: InsightSummary?
    @State private var showPaywall = false

    private var hasData: Bool { !entries.isEmpty }

    var body: some View {
        NavigationStack {
            Group {
                if !hasData {
                    ScrollView {
                        EmptyStateView(
                            icon: "chart.xyaxis.line",
                            title: "Insights will appear here",
                            message: "Log a few sessions and Caliper will chart your trends and compute body-composition metrics.")
                        .padding(.top, 60)
                    }
                } else {
                    content
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Insights")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .task(id: window) { await recompute() }
            .onChange(of: entries.count) { _, _ in
                Task { await recompute() }
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                windowPicker

                if isComputing {
                    HStack {
                        Spacer()
                        ProgressView("Computing insights…")
                            .tint(Theme.accent)
                            .padding(.vertical, 40)
                        Spacer()
                    }
                } else {
                    trendChart(key: "weight", title: "Weight trend", smoothed: true)
                    trendChart(key: "bodyfat", title: "Body-fat trend", smoothed: true)
                    trendChart(key: "waist", title: "Waist trend", smoothed: false)
                    compositionCard
                    if let summary {
                        statsCard(summary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
    }

    private var windowPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Picker("Window", selection: $window) {
                ForEach(InsightWindow.allCases) { w in
                    Text(w.label).tag(w)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: window) { oldValue, newValue in
                if newValue.proOnly && !proStore.isPro {
                    window = oldValue
                    showPaywall = true
                } else {
                    Haptics.selection(enabled: settings.hapticsEnabled)
                }
            }
            if !proStore.isPro {
                Text("30-day window is free. Unlock Pro for 90d / 1y / all-time.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: Data windowing

    private var cutoff: Date? {
        guard window != .all else { return nil }
        return Calendar.current.date(byAdding: .day, value: -window.rawValue, to: Date())
    }

    private func windowedEntries(_ key: String) -> [MeasurementEntry] {
        let filtered = entries.filter { $0.siteKey == key }.sorted { $0.date < $1.date }
        guard let cutoff else { return filtered }
        return filtered.filter { $0.date >= cutoff }
    }

    private func site(_ key: String) -> MeasurementSite? {
        sites.first { $0.key == key }
    }

    // MARK: Trend chart

    @ViewBuilder
    private func trendChart(key: String, title: String, smoothed: Bool) -> some View {
        if let site = site(key) {
            let raw = windowedEntries(key)
            let kind = site.unitKind
            let unit = Units.unitLabel(kind: kind, system: settings.unitSystem)
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.ink)
                if raw.count < 2 {
                    Text("Not enough data in this window yet.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                        .frame(height: 80)
                } else {
                    let display = raw.map { Units.displayValue(canonical: $0.valueCanonical, kind: kind, system: settings.unitSystem) }
                    let smoothedVals = smoothed ? BodyMath.smoothed(display, window: 3) : display
                    let points = zip(raw, smoothedVals).map { ChartPoint(date: $0.0.date, value: $0.1) }
                    Chart(points) { p in
                        LineMark(x: .value("Date", p.date), y: .value(title, p.value))
                            .foregroundStyle(Theme.accent)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                        AreaMark(x: .value("Date", p.date), y: .value(title, p.value))
                            .foregroundStyle(LinearGradient(colors: [Theme.accent.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
                            .interpolationMethod(.catmullRom)
                    }
                    .chartYScale(domain: .automatic(includesZero: false))
                    .frame(height: 160)
                    .accessibilityLabel(title)
                    .accessibilityValue(chartSummary(raw, kind: kind, unit: unit))
                }
            }
            .padding(16)
            .cardSurface()
        }
    }

    private func chartSummary(_ entries: [MeasurementEntry], kind: UnitKind, unit: String) -> String {
        let stats = SiteStats.compute(entries: entries)
        guard let first = stats.current, let total = stats.totalChange else { return "No data" }
        let c = Units.formatted(canonical: first, kind: kind, system: settings.unitSystem)
        let t = Units.displayValue(canonical: total, kind: kind, system: settings.unitSystem)
        let dir = total < 0 ? "down" : (total > 0 ? "up" : "flat")
        return "Latest \(c) \(unit), \(dir) \(Units.number(abs(t), digits: 1)) \(unit) over the window"
    }

    // MARK: Composition

    private var compositionCard: some View {
        let bars = compositionBars()
        return VStack(alignment: .leading, spacing: 10) {
            Text("Composition (latest)")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.ink)
            if bars.isEmpty {
                Text("Log weight and body-fat to see fat vs lean mass.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
            } else {
                Chart(bars) { bar in
                    BarMark(x: .value("Mass", bar.value), y: .value("Component", bar.label))
                        .foregroundStyle(bar.color)
                        .annotation(position: .trailing) {
                            Text("\(Units.number(Units.displayValue(canonical: bar.value, kind: .mass, system: settings.unitSystem), digits: 1)) \(settings.unitSystem.massUnit)")
                                .font(.caption2)
                                .foregroundStyle(Theme.inkSoft)
                        }
                }
                .frame(height: 110)
                .accessibilityLabel("Body composition")
                .accessibilityValue(bars.map { "\($0.label) \(Units.number($0.value, digits: 1)) kilograms" }.joined(separator: ", "))
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func compositionBars() -> [CompositionBar] {
        guard let w = windowedEntries("weight").last?.valueCanonical,
              let bf = windowedEntries("bodyfat").last?.valueCanonical,
              w > 0, bf >= 0, bf < 100 else { return [] }
        let fat = w * bf / 100
        let lean = w - fat
        return [
            CompositionBar(label: "Lean", value: lean, color: Theme.accent),
            CompositionBar(label: "Fat", value: fat, color: Theme.warn)
        ]
    }

    // MARK: Stats card

    private func statsCard(_ s: InsightSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Computed stats")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.ink)
            statRow("Weight weekly rate", s.weightRate)
            statRow("Body-fat weekly rate", s.bodyFatRate)
            statRow("Waist weekly rate", s.waistRate)
            Divider().overlay(Theme.hairline)
            statRow("BMI", s.bmi)
            statRow("Waist : Hip", s.whr)
            statRow("FFMI (normalized)", proStore.isPro ? s.ffmi : "Pro")
        }
        .padding(16)
        .cardSurface()
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.rounded(14, .medium))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(Theme.ink)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }

    // MARK: Recompute (async loading state)

    @MainActor
    private func recompute() async {
        isComputing = true
        // Brief yield so the spinner is visible and the UI stays responsive.
        try? await Task.sleep(nanoseconds: 350_000_000)
        summary = buildSummary()
        isComputing = false
    }

    private func buildSummary() -> InsightSummary {
        func rate(_ key: String) -> String {
            let e = windowedEntries(key)
            guard let site = site(key) else { return "—" }
            guard let r = BodyMath.weeklyRate(points: e.map { ($0.date, $0.valueCanonical) }) else {
                return "Need 2+"
            }
            let d = Units.displayValue(canonical: r, kind: site.unitKind, system: settings.unitSystem)
            let sign = d > 0 ? "+" : ""
            return "\(sign)\(Units.number(d, digits: 2)) \(Units.unitLabel(kind: site.unitKind, system: settings.unitSystem))/wk"
        }

        let w = windowedEntries("weight").last?.valueCanonical
        let bf = windowedEntries("bodyfat").last?.valueCanonical
        let waist = windowedEntries("waist").last?.valueCanonical
        let hip = windowedEntries("hips").last?.valueCanonical

        var bmiStr = "—"
        if let w, let b = BodyMath.bmi(weightKg: w, heightCm: settings.heightCm) {
            bmiStr = "\(Units.number(b, digits: 1)) · \(BodyMath.bmiCategory(b))"
        }
        var whrStr = "—"
        if let waist, let hip, let r = BodyMath.waistToHip(waistCm: waist, hipCm: hip) {
            whrStr = "\(Units.number(r, digits: 2)) · \(BodyMath.waistToHipCategory(r, sex: settings.biologicalSex))"
        }
        var ffmiStr = "—"
        if let w, let bf, let f = BodyMath.ffmi(weightKg: w, bodyFatPercent: bf, heightCm: settings.heightCm) {
            ffmiStr = Units.number(f.normalized, digits: 1)
        }

        return InsightSummary(
            weightRate: rate("weight"),
            bodyFatRate: rate("bodyfat"),
            waistRate: rate("waist"),
            bmi: bmiStr,
            whr: whrStr,
            ffmi: ffmiStr
        )
    }
}

struct InsightSummary {
    let weightRate: String
    let bodyFatRate: String
    let waistRate: String
    let bmi: String
    let whr: String
    let ffmi: String
}

struct CompositionBar: Identifiable {
    let id = UUID()
    let label: String
    let value: Double  // canonical kg
    let color: Color
}
