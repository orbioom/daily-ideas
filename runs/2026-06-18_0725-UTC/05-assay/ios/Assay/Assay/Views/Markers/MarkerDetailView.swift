import SwiftUI
import SwiftData
import Charts

/// Marker detail: history line chart with reference + optimal band shading,
/// latest value & status, trend, plain-language description, unit toggle.
struct MarkerDetailView: View {
    let marker: Biomarker

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Query private var results: [LabResult]

    @State private var useAltUnit = false
    @State private var didInitUnit = false
    @State private var showPaywall = false

    private var sex: BiologicalSex { settings.biologicalSex }

    /// Currently chosen display unit. `useAltUnit` directly means "show the
    /// marker's alternate unit"; it's seeded from the global preference.
    private var altUnit: AltUnit? {
        guard let alt = marker.altUnit else { return nil }
        return useAltUnit ? alt : nil
    }

    private var unitLabel: String { altUnit?.unit ?? marker.unit }

    private var samples: [TrendSample] {
        LabAnalytics.samples(for: marker.id, results: results)
    }

    private var latestSnapshot: MarkerSnapshot? {
        let snaps = LabAnalytics.latestSnapshots(from: results, sex: sex)
        return snaps.first { $0.marker.id == marker.id }
    }

    private var trend: MarkerTrend? {
        let mid = LabAnalytics.optimalMid(for: marker, sex: sex)
        return TrendEngine.trend(for: samples, goodDirection: marker.direction, optimalMid: mid)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                latestCard
                if marker.altUnit != nil { unitToggle }
                chartCard
                aboutCard
                rangeCard
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(marker.shortName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear {
            // Seed the unit toggle from the user's global unit preference once.
            if !didInitUnit {
                useAltUnit = settings.preferredAltUnit(for: marker) != nil
                didInitUnit = true
            }
        }
    }

    // MARK: - Latest

    @ViewBuilder
    private var latestCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(marker.name)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)

            if let snap = latestSnapshot {
                let display = UnitConverter.display(canonical: snap.assessment.canonicalValue, altUnit: altUnit)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(Fmt.value(display))
                        .font(Theme.rounded(40, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(unitLabel)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    StatusChip(status: snap.assessment.status)
                }

                RangeBandView(marker: marker, sex: sex, assessment: snap.assessment, showOptimal: settings.showOptimalRanges)
                    .padding(.top, 2)

                HStack {
                    Text("Measured \(Fmt.date(snap.drawDate))")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    if let t = trend, t.pointCount >= 2 {
                        TrendBadge(trend: t)
                    }
                }
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "tray")
                        .foregroundStyle(Theme.inkSoft)
                    Text("No readings yet. Log this marker to start tracking it.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .assayCard()
    }

    private var unitToggle: some View {
        HStack {
            Text("Display unit")
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Picker("Display unit", selection: $useAltUnit) {
                Text(marker.unit).tag(false)
                if let alt = marker.altUnit { Text(alt.unit).tag(true) }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
        }
        .assayCard(padding: 12)
    }

    // MARK: - Chart

    private struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    private var chartPoints: [ChartPoint] {
        samples.map { s in
            ChartPoint(date: s.date, value: UnitConverter.display(canonical: s.canonicalValue, altUnit: altUnit))
        }
    }

    @ViewBuilder
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History")
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if !chartPoints.isEmpty {
                    Text("\(chartPoints.count) readings")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft)
                }
            }

            if chartPoints.count < 2 {
                Text(chartPoints.isEmpty ? "No history to chart yet." : "Log at least two readings to see a trend line.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                chart
                    .frame(height: 200)
                legend
            }
        }
        .assayCard()
    }

    private var stdRange: ClinicalRange { marker.standard.range(for: sex) }
    private var optRange: ClinicalRange { marker.optimal.range(for: sex) }

    private func boundDisplay(_ v: Double?) -> Double? {
        UnitConverter.displayBound(v, altUnit: altUnit)
    }

    @ViewBuilder
    private var chart: some View {
        let optLo = boundDisplay(optRange.low)
        let optHi = boundDisplay(optRange.high)
        let stdLo = boundDisplay(stdRange.low)
        let stdHi = boundDisplay(stdRange.high)

        Chart {
            // Optimal band shading.
            if let lo = optLo, let hi = optHi {
                RectangleMark(
                    xStart: .value("Start", chartXDomain.lowerBound),
                    xEnd: .value("End", chartXDomain.upperBound),
                    yStart: .value("Opt low", lo),
                    yEnd: .value("Opt high", hi)
                )
                .foregroundStyle(Theme.good.opacity(0.14))
            }
            // Standard reference lines.
            if let lo = stdLo {
                RuleMark(y: .value("Ref low", lo))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Theme.okay.opacity(0.6))
            }
            if let hi = stdHi {
                RuleMark(y: .value("Ref high", hi))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Theme.okay.opacity(0.6))
            }
            // History line + points.
            ForEach(chartPoints) { p in
                LineMark(x: .value("Date", p.date), y: .value("Value", p.value))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Theme.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                PointMark(x: .value("Date", p.date), y: .value("Value", p.value))
                    .foregroundStyle(Theme.accent)
                    .symbolSize(60)
            }
        }
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisValueLabel()
            }
        }
        .accessibilityLabel("\(marker.name) history")
        .accessibilityValue(chartAccessibility)
    }

    private var chartXDomain: ClosedRange<Date> {
        let dates = chartPoints.map { $0.date }
        guard let lo = dates.min(), let hi = dates.max() else {
            let now = Date()
            return now...now
        }
        if lo == hi { return lo...hi.addingTimeInterval(86_400) }
        return lo...hi
    }

    /// Y domain padded around data and visible reference bounds. Guarded.
    private var yDomain: ClosedRange<Double> {
        var vals = chartPoints.map { $0.value }
        if let lo = boundDisplay(optRange.low) { vals.append(lo) }
        if let hi = boundDisplay(optRange.high) { vals.append(hi) }
        if let lo = boundDisplay(stdRange.low) { vals.append(lo) }
        if let hi = boundDisplay(stdRange.high) { vals.append(hi) }
        guard let mn = vals.min(), let mx = vals.max() else { return 0...1 }
        if mn == mx {
            let pad = abs(mn) * 0.1 + 1
            return (mn - pad)...(mx + pad)
        }
        let span = mx - mn
        let pad = span * 0.12
        return (mn - pad)...(mx + pad)
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendDot(color: Theme.accent, label: "Your readings")
            legendDot(color: Theme.good.opacity(0.5), label: "Optimal")
            legendDot(color: Theme.okay.opacity(0.7), label: "Reference")
        }
        .font(.caption2)
        .foregroundStyle(Theme.inkSoft)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
        }
    }

    private var chartAccessibility: String {
        guard let first = chartPoints.first, let last = chartPoints.last else { return "No data" }
        return "From \(Fmt.value(first.value)) on \(Fmt.date(first.date)) to \(Fmt.value(last.value)) \(unitLabel) on \(Fmt.date(last.date))"
    }

    // MARK: - About / range

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("About this marker", systemImage: "info.circle.fill")
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(Theme.ink)
            Text(marker.info)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Text("Reference values are general adult ranges and are not a diagnosis. Discuss results with your clinician.")
                .font(.caption2)
                .foregroundStyle(Theme.inkFaint)
                .padding(.top, 2)
        }
        .assayCard()
    }

    private var rangeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ranges (\(sex.shortLabel == "—" ? "general" : sex.rawValue))")
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(Theme.ink)
            rangeRow(label: "Standard", range: stdRange, color: Theme.okay)
            rangeRow(label: "Optimal", range: optRange, color: Theme.good)
            directionRow
        }
        .assayCard()
    }

    private func rangeRow(label: String, range: ClinicalRange, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(.subheadline).foregroundStyle(Theme.ink)
            Spacer()
            Text(rangeText(range)).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
        }
    }

    private func rangeText(_ r: ClinicalRange) -> String {
        let lo = boundDisplay(r.low)
        let hi = boundDisplay(r.high)
        switch (lo, hi) {
        case let (l?, h?): return "\(Fmt.value(l))–\(Fmt.value(h)) \(unitLabel)"
        case let (l?, nil): return "≥ \(Fmt.value(l)) \(unitLabel)"
        case let (nil, h?): return "≤ \(Fmt.value(h)) \(unitLabel)"
        case (nil, nil): return "—"
        }
    }

    private var directionRow: some View {
        HStack {
            Image(systemName: "arrow.up.arrow.down")
                .font(.caption)
                .foregroundStyle(Theme.inkSoft)
            Text(directionText)
                .font(.caption)
                .foregroundStyle(Theme.inkSoft)
            Spacer()
        }
    }

    private var directionText: String {
        switch marker.direction {
        case .higherBetter: return "Higher is generally better"
        case .higherWorse: return "Lower is generally better"
        case .midOptimal: return "Best within the optimal window"
        }
    }
}
