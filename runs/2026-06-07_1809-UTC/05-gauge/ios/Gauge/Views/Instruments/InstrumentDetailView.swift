import SwiftUI
import SwiftData
import Charts

/// The heart of the app: a full per-string tension table for one instrument,
/// with totals, balance, a bar chart, live scale-length editing, inline string
/// editing, and apply-set / apply-tuning actions from the Library.
struct InstrumentDetailView: View {
    @Bindable var instrument: Instrument
    @Environment(\.modelContext) private var context
    @AppStorage("gauge.unit") private var unitRaw = WeightUnit.pounds.rawValue

    @State private var showEdit = false
    @State private var showApplySet = false
    @State private var showApplyTuning = false
    @State private var editingSlot: StringSlot?

    /// The cached tension summary. Nil until the first computation completes,
    /// which drives the loading state. Recomputed whenever inputs change.
    @State private var summary: TensionEngine.Summary?

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .pounds }

    /// A signature of the inputs that affect the summary, so a change triggers a
    /// recompute without re-running on every unrelated redraw.
    private var inputSignature: String {
        let stringsPart = instrument.orderedStrings
            .map { "\($0.position):\($0.noteName):\($0.gaugeThou):\($0.materialRaw)" }
            .joined(separator: "|")
        return "\(instrument.scaleLengthIn)#\(stringsPart)"
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 16) {
                    header
                    scaleControl
                    if instrument.strings.isEmpty {
                        EmptyStateView(icon: "lines.measurement.horizontal",
                                       title: "No strings",
                                       message: "Apply a string set to start computing tension.")
                            .glassCard()
                    } else if let summary {
                        summaryTiles(summary)
                        chartCard(summary)
                        stringTable(summary)
                    } else {
                        loadingCard
                    }
                    actionButtons
                }
                .padding(16)
            }
        }
        .navigationTitle(instrument.name)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: inputSignature) { await recompute() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            InstrumentEditSheet(instrument: instrument, isNew: false, onCancelNew: {})
        }
        .sheet(item: $editingSlot) { slot in
            StringEditSheet(slot: slot, instrument: instrument)
        }
        .sheet(isPresented: $showApplySet) {
            ApplyPickerSheet(instrument: instrument, mode: .set)
        }
        .sheet(isPresented: $showApplyTuning) {
            ApplyPickerSheet(instrument: instrument, mode: .tuning)
        }
    }

    // MARK: - Sections

    private var header: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: instrument.type.symbol)
                    .font(.title)
                    .foregroundStyle(Brand.text2)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: instrument.type.label)
                    Text(instrument.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Brand.text)
                    if !instrument.notes.isEmpty {
                        Text(instrument.notes)
                            .font(.caption)
                            .foregroundStyle(Brand.text2)
                    }
                }
                Spacer()
            }
        }
    }

    private var scaleControl: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionTitle(text: "Scale length")
                    Spacer()
                    Text(String(format: "%.2f\"", instrument.scaleLengthIn))
                        .font(Brand.mono(15, weight: .semibold))
                        .foregroundStyle(Brand.text)
                }
                Slider(value: scaleBinding, in: 12...40, step: 0.05) {
                    Text("Scale length")
                } minimumValueLabel: {
                    Text("12\"").font(Brand.mono(10)).foregroundStyle(Brand.text3)
                } maximumValueLabel: {
                    Text("40\"").font(Brand.mono(10)).foregroundStyle(Brand.text3)
                }
                .accessibilityValue(String(format: "%.2f inches", instrument.scaleLengthIn))
                Text("Drag to see how scale length changes tension live.")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
        }
    }

    private var loadingCard: some View {
        GlassCard {
            HStack(spacing: 12) {
                ProgressView()
                Text("Computing tension…")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
        }
        .accessibilityLabel("Computing tension")
    }

    private func summaryTiles(_ summary: TensionEngine.Summary) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatTile(value: unit.format(fromLb: summary.totalLb, decimals: 1),
                         label: "Total tension")
                StatTile(value: unit.format(fromLb: summary.balanceLb, decimals: 1),
                         label: "Balance spread",
                         accent: balanceColor(summary.balanceLb))
            }
            HStack(spacing: 12) {
                StatTile(value: unit.format(fromLb: summary.averageLb, decimals: 1),
                         label: "Average / string")
                StatTile(value: "\(summary.validCount)/\(instrument.strings.count)",
                         label: "Strings valid")
            }
            if summary.hasInvalid {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                    Text("Some strings have a note Gauge can't read. Tap a row to fix it.")
                }
                .font(.footnote)
                .foregroundStyle(Brand.warn)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func chartCard(_ summary: TensionEngine.Summary) -> some View {
        let points = summary.perString.compactMap { item -> (String, Double, Color)? in
            guard let t = item.tension, t.isFinite else { return nil }
            let comfort = TensionEngine.comfort(tensionLb: t, isBass: instrument.type.isBass)
            return (item.slot.noteName, unit.value(fromLb: t), comfort.color)
        }
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "Tension per string (\(unit.short))")
                if points.isEmpty {
                    Text("No valid strings to chart.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                        .frame(maxWidth: .infinity, minHeight: 80)
                } else {
                    Chart {
                        ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                            BarMark(
                                x: .value("String", "\(index + 1) · \(point.0)"),
                                y: .value("Tension", point.1)
                            )
                            .foregroundStyle(point.2)
                            .cornerRadius(4)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 180)
                    .accessibilityLabel("Bar chart of tension per string")
                }
            }
        }
    }

    private func stringTable(_ summary: TensionEngine.Summary) -> some View {
        let maxTension = max(summary.maxLb, 0.0001)
        return GlassCard {
            VStack(alignment: .leading, spacing: 0) {
                SectionTitle(text: "Strings")
                    .padding(.bottom, 8)
                ForEach(Array(summary.perString.enumerated()), id: \.element.slot.id) { index, item in
                    Button {
                        Haptics.tap()
                        editingSlot = item.slot
                    } label: {
                        StringRow(slot: item.slot,
                                  tensionLb: item.tension,
                                  maxLb: maxTension,
                                  isBass: instrument.type.isBass,
                                  unit: unit)
                    }
                    .buttonStyle(.plain)
                    if index < summary.perString.count - 1 {
                        Divider().overlay(Brand.hairline)
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.tap(); showApplySet = true
            } label: { Label("Apply string set", systemImage: "square.stack.3d.up") }
                .buttonStyle(GlassButtonStyle())
            Button {
                Haptics.tap(); showApplyTuning = true
            } label: { Label("Apply tuning", systemImage: "tuningfork") }
                .buttonStyle(GlassButtonStyle())
        }
    }

    // MARK: - Helpers

    /// Recomputes the cached summary off the current inputs. Yielding first lets
    /// the loading card render before a larger string set is crunched.
    private func recompute() async {
        if summary == nil { await Task.yield() }
        let computed = TensionEngine.summary(for: instrument)
        if !Task.isCancelled { summary = computed }
    }

    private var scaleBinding: Binding<Double> {
        Binding(
            get: { min(max(instrument.scaleLengthIn, 12), 40) },
            set: { newValue in
                let clamped = min(max(newValue, 12), 40)
                if abs(clamped - instrument.scaleLengthIn) > 0.001 {
                    instrument.scaleLengthIn = clamped
                }
            }
        )
    }

    private func balanceColor(_ spread: Double) -> Color {
        // A tighter spread is better balanced. Thresholds differ for bass.
        let limit = instrument.type.isBass ? 16.0 : 6.0
        if spread <= limit { return Brand.live }
        if spread <= limit * 2 { return Brand.warn }
        return Brand.danger
    }
}

/// One string row in the detail table.
private struct StringRow: View {
    let slot: StringSlot
    let tensionLb: Double?
    let maxLb: Double
    let isBass: Bool
    let unit: WeightUnit

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Text("\(slot.position)")
                    .font(Brand.mono(12, weight: .semibold))
                    .foregroundStyle(Brand.text3)
                    .frame(width: 18)
                if let tensionLb, tensionLb.isFinite {
                    StatusDot(color: TensionEngine.comfort(tensionLb: tensionLb, isBass: isBass).color)
                } else {
                    StatusDot(color: Brand.danger)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(slot.noteName)
                        .font(Brand.mono(15, weight: .medium))
                        .foregroundStyle(Brand.text)
                    Text("\(slot.gaugeLabel)\"  ·  \(slot.material.shortLabel)")
                        .font(Brand.mono(11))
                        .foregroundStyle(Brand.text2)
                }
                Spacer()
                if let tensionLb, tensionLb.isFinite {
                    Text(unit.format(fromLb: tensionLb, decimals: 1))
                        .font(Brand.mono(15, weight: .semibold))
                        .foregroundStyle(Brand.text)
                } else {
                    Text("—")
                        .font(Brand.mono(15, weight: .semibold))
                        .foregroundStyle(Brand.danger)
                }
            }
            MeterBar(fraction: fraction,
                     color: barColor,
                     height: 6)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Double tap to edit this string")
    }

    private var fraction: Double {
        guard let t = tensionLb, t.isFinite, maxLb > 0 else { return 0 }
        return t / maxLb
    }

    private var barColor: Color {
        guard let t = tensionLb, t.isFinite else { return Brand.danger }
        return TensionEngine.comfort(tensionLb: t, isBass: isBass).color
    }

    private var accessibilityText: String {
        let base = "String \(slot.position), \(slot.noteName), \(slot.gaugeLabel) inch \(slot.material.label)"
        if let t = tensionLb, t.isFinite {
            return base + ", \(unit.format(fromLb: t))"
        }
        return base + ", invalid note"
    }
}
