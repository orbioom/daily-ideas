import SwiftUI
import SwiftData

/// The growth screen for one child: measure toggle, percentile chart, plain-language readout,
/// and the editable measurement history.
struct GrowthDetailView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Bindable var child: Child

    @State private var measure: GrowthMeasure = .weight
    @State private var showAdd = false
    @State private var editing: GrowthMeasurement?
    @State private var didSetDefault = false

    private var measurements: [GrowthMeasurement] {
        child.sortedMeasurements.reversed()
    }

    /// Latest measurement that has a value for the current measure.
    private var latestForMeasure: GrowthMeasurement? {
        child.sortedMeasurements.last { $0.value(for: measure) != nil }
    }

    private var latestResult: PercentileResult? {
        guard let m = latestForMeasure, let v = m.value(for: measure) else { return nil }
        let age = child.ageMonthsExact(asOf: m.date)
        return PercentileEngine.evaluate(value: v, measure: measure, sex: child.sex, ageMonths: age)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                measurePicker
                if child.measurements.isEmpty {
                    emptyState
                } else {
                    chartCard
                    readoutCard
                    historySection
                }
                disclaimer
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Growth")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add measurement")
            }
        }
        .sheet(isPresented: $showAdd) {
            AddMeasurementView(child: child)
        }
        .sheet(item: $editing) { m in
            AddMeasurementView(child: child, existing: m)
        }
        .onAppear {
            if !didSetDefault {
                measure = settings.defaultMeasure
                didSetDefault = true
            }
        }
    }

    private var measurePicker: some View {
        Picker("Measure", selection: $measure) {
            ForEach(GrowthMeasure.allCases) { m in
                Text(m.shortTitle).tag(m)
            }
        }
        .pickerStyle(.segmented)
    }

    private var chartCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SectionHeader(title: "\(measure.title) · \(settings.growthStandard.short)", systemImage: measure.symbol)
                    if !isPro {
                        StatusPill(text: "P3·P50·P97", color: Theme.inkSoft)
                    }
                }
                GrowthChart(child: child,
                            measure: measure,
                            mass: settings.massUnit,
                            length: settings.lengthUnit,
                            showAllOverlays: isPro)
                Text(isPro ? "Showing all five WHO percentile curves."
                           : "Free shows the 3rd, 50th, and 97th curves. Sprig Pro adds all five.")
                    .font(Theme.rounded(11))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
    }

    private var readoutCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Where \(child.displayName) stands", systemImage: "target")
                if let result = latestResult, let m = latestForMeasure, let v = m.value(for: measure) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(PercentileEngine.ordinal(result.percentile))
                            .font(Theme.rounded(34, .bold))
                            .foregroundStyle(ChildColors.color(hex: child.colorHex))
                        Text("percentile")
                            .font(Theme.rounded(16, .medium))
                            .foregroundStyle(Theme.inkSoft)
                        Spacer()
                        Text(settings.format(v, measure: measure))
                            .font(Theme.rounded(18, .semibold))
                            .foregroundStyle(Theme.ink)
                    }
                    Text(PercentileEngine.interpretation(percentile: result.percentile))
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Measured at \(AgeMath.description(from: child.birthDate, to: m.date)) · median is \(settings.format(result.median, measure: measure))")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                } else {
                    Text("No \(measure.title.lowercased()) recorded yet. Add a measurement to see the percentile.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "History", systemImage: "list.bullet")
            LazyVStack(spacing: 10) {
                ForEach(measurements) { m in
                    MeasurementRow(child: child, measurement: m, measure: measure, settings: settings)
                        .contextMenu {
                            Button { editing = m } label: { Label("Edit", systemImage: "pencil") }
                            Button(role: .destructive) { delete(m) } label: { Label("Delete", systemImage: "trash") }
                        }
                        .onTapGesture { editing = m }
                }
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(symbol: "chart.xyaxis.line",
                       title: "No measurements yet",
                       message: "Add \(child.displayName)'s first weight, height, or head circumference to plot percentiles.",
                       actionTitle: "Add measurement") {
            showAdd = true
        }
    }

    private var disclaimer: some View {
        Text("Percentiles are based on WHO Child Growth Standards and are informational only — not medical advice.")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
    }

    private func delete(_ m: GrowthMeasurement) {
        context.delete(m)
        try? context.save()
        Haptics.warn(settings.hapticsEnabled)
    }
}

/// One row in the measurement history. Shows the value for the active measure and its percentile.
private struct MeasurementRow: View {
    let child: Child
    let measurement: GrowthMeasurement
    let measure: GrowthMeasure
    let settings: AppSettings

    private var result: PercentileResult? {
        guard let v = measurement.value(for: measure) else { return nil }
        let age = child.ageMonthsExact(asOf: measurement.date)
        return PercentileEngine.evaluate(value: v, measure: measure, sex: child.sex, ageMonths: age)
    }

    var body: some View {
        CardView(padding: 14) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(measurement.date.formatted(date: .abbreviated, time: .omitted))
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(AgeMath.description(from: child.birthDate, to: measurement.date))
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                    if let note = measurement.note, !note.isEmpty {
                        Text(note)
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                            .lineLimit(1)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if let v = measurement.value(for: measure) {
                        Text(settings.format(v, measure: measure))
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.ink)
                        if let result {
                            Text(PercentileEngine.ordinal(result.percentile))
                                .font(Theme.rounded(12, .semibold))
                                .foregroundStyle(Theme.accent)
                        }
                    } else {
                        Text("—")
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
