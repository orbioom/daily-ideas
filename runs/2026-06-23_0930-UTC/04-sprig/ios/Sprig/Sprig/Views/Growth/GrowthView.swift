import SwiftUI
import SwiftData
import Charts

/// Growth journey: simple weight & length charts plus a measurement log with
/// full add/edit/delete. No percentile claims — just your baby's own curve.
struct GrowthView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @AppStorage(PrefKey.weightUnit) private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage(PrefKey.lengthUnit) private var lengthUnitRaw = LengthUnit.cm.rawValue
    @AppStorage(PrefKey.hapticsEnabled) private var haptics = true
    @AppStorage(PrefKey.confirmDelete) private var confirmDelete = true

    @Bindable var baby: Baby

    @State private var metric: Metric = .weight
    @State private var showAdd = false
    @State private var editing: GrowthEntry?
    @State private var pendingDelete: GrowthEntry?

    enum Metric: String, CaseIterable, Identifiable {
        case weight, length
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    private var wUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .kg }
    private var lUnit: LengthUnit { LengthUnit(rawValue: lengthUnitRaw) ?? .cm }

    private var entries: [GrowthEntry] {
        baby.growth.sorted { $0.date > $1.date }
    }

    private var weightPts: [SprigEngine.GrowthPoint] { SprigEngine.weightSeries(for: baby) }
    private var lengthPts: [SprigEngine.GrowthPoint] { SprigEngine.lengthSeries(for: baby) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ambientGradient(scheme).ignoresSafeArea()
                if entries.isEmpty {
                    EmptyStateView(
                        systemImage: "ruler",
                        title: "No measurements yet",
                        message: "Add a weight or length and watch \(baby.name)'s growth curve take shape.",
                        actionTitle: "Add measurement",
                        action: { showAdd = true }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            summary
                            picker
                            chartCard
                            historyList
                        }
                        .padding(16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Growth")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add measurement")
                }
            }
            .sheet(isPresented: $showAdd) { GrowthEditorView(baby: baby, existing: nil) }
            .sheet(item: $editing) { entry in GrowthEditorView(baby: baby, existing: entry) }
            .confirmationDialog("Delete this measurement?",
                                isPresented: Binding(get: { pendingDelete != nil },
                                                     set: { if !$0 { pendingDelete = nil } }),
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let e = pendingDelete { delete(e) }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    // MARK: Summary

    private var summary: some View {
        let latestW = weightPts.last
        let latestL = lengthPts.last
        let gain = SprigEngine.weightGain(for: baby)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            StatTile(icon: "scalemass.fill",
                     value: latestW.map { "\(Fmt.num(wUnit.display(fromGrams: $0.value), decimals: 2)) \(wUnit.label)" } ?? "—",
                     label: "Latest weight", tint: Theme.gold)
            StatTile(icon: "ruler.fill",
                     value: latestL.map { "\(Fmt.num(lUnit.display(fromCM: $0.value))) \(lUnit.label)" } ?? "—",
                     label: "Latest length", tint: Theme.accent)
            StatTile(icon: "arrow.up.right",
                     value: gain.map { "+\(Fmt.num(wUnit.display(fromGrams: max(0, $0)), decimals: 2))" } ?? "—",
                     label: "Weight gain", tint: Theme.apricot)
        }
    }

    private var picker: some View {
        Picker("Metric", selection: $metric) {
            ForEach(Metric.allCases) { Text($0.label).tag($0) }
        }
        .pickerStyle(.segmented)
        .onChange(of: metric) { _, _ in Haptics.selection(haptics) }
    }

    // MARK: Chart

    @ViewBuilder
    private var chartCard: some View {
        let points = metric == .weight ? weightPts : lengthPts
        let unitLabel = metric == .weight ? wUnit.label : lUnit.label
        let convert: (Double) -> Double = metric == .weight
            ? { wUnit.display(fromGrams: $0) }
            : { lUnit.display(fromCM: $0) }

        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: metric == .weight ? "Weight over time" : "Length over time",
                              systemImage: metric == .weight ? "scalemass.fill" : "ruler.fill")
                if points.count < 2 {
                    Text("Add at least two \(metric.label.lowercased()) measurements to see a curve.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText(scheme))
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    Chart(points) { p in
                        LineMark(
                            x: .value("Date", p.date, unit: .day),
                            y: .value("Value", convert(p.value))
                        )
                        .foregroundStyle(metric == .weight ? Theme.gold : Theme.accent)
                        .interpolationMethod(.catmullRom)
                        AreaMark(
                            x: .value("Date", p.date, unit: .day),
                            y: .value("Value", convert(p.value))
                        )
                        .foregroundStyle((metric == .weight ? Theme.gold : Theme.accent).opacity(0.14).gradient)
                        .interpolationMethod(.catmullRom)
                        PointMark(
                            x: .value("Date", p.date, unit: .day),
                            y: .value("Value", convert(p.value))
                        )
                        .foregroundStyle(metric == .weight ? Theme.gold : Theme.accent)
                        .symbolSize(26)
                    }
                    .chartYScale(domain: .automatic(includesZero: false))
                    .chartYAxisLabel(unitLabel)
                    .frame(height: 200)
                    .accessibilityLabel("\(metric.label) chart over time")
                }
            }
        }
    }

    // MARK: History

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Measurement log", systemImage: "list.bullet")
            Card(padding: 6) {
                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        Button { editing = entry } label: { historyRow(entry) }
                            .buttonStyle(.plain)
                        if index < entries.count - 1 {
                            Divider().padding(.leading, 12)
                        }
                    }
                }
            }
        }
    }

    private func historyRow(_ entry: GrowthEntry) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Fmt.shortDay(entry.date))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.primaryText(scheme))
                Text(measurementText(entry))
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText(scheme))
            }
            Spacer()
            Button(role: .destructive) {
                requestDelete(entry)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(Theme.clay)
                    .padding(8)
            }
            .accessibilityLabel("Delete measurement from \(Fmt.shortDay(entry.date))")
        }
        .padding(12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Fmt.shortDay(entry.date)), \(measurementText(entry))")
        .accessibilityHint("Double tap to edit")
    }

    private func measurementText(_ entry: GrowthEntry) -> String {
        var parts: [String] = []
        if entry.hasWeight {
            parts.append("\(Fmt.num(wUnit.display(fromGrams: entry.weightGrams), decimals: 2)) \(wUnit.label)")
        }
        if entry.hasLength {
            parts.append("\(Fmt.num(lUnit.display(fromCM: entry.lengthCM))) \(lUnit.label)")
        }
        return parts.isEmpty ? "No data" : parts.joined(separator: " · ")
    }

    private func requestDelete(_ entry: GrowthEntry) {
        if confirmDelete { pendingDelete = entry } else { delete(entry) }
    }

    private func delete(_ entry: GrowthEntry) {
        context.delete(entry)
        try? context.save()
        Haptics.warning(haptics)
    }
}
