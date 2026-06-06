import SwiftUI
import SwiftData

/// Gauge calculator: turns a gauge swatch into a cast-on count and row count.
struct GaugeCalcView: View {
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.imperial.rawValue

    @State private var stitchesText = ""
    @State private var rowsText = ""
    @State private var widthText = ""
    @State private var lengthText = ""
    @State private var prefillProject: Project?

    private var unit: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .imperial }
    private var gaugeSts: Double { parse(stitchesText) }
    private var gaugeRows: Double { parse(rowsText) }
    private var widthIn: Double { GaugeMath.inches(from: parse(widthText), unit: unit) }
    private var lengthIn: Double { GaugeMath.inches(from: parse(lengthText), unit: unit) }

    private var castOn: Int { GaugeMath.castOn(gaugeStitchesPer4in: gaugeSts, widthInches: widthIn) }
    private var rowCount: Int { GaugeMath.rows(gaugeRowsPer4in: gaugeRows, lengthInches: lengthIn) }
    private var hasResult: Bool { castOn > 0 || rowCount > 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !projects.isEmpty { prefillCard }
                inputCard
                resultCard
            }
            .padding(.horizontal, 16).padding(.vertical, 8).padding(.bottom, 28)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Gauge")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var prefillCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Prefill gauge from a project")
            Menu {
                ForEach(projects.filter { $0.hasGauge }) { p in
                    Button(p.name.isEmpty ? "Untitled" : p.name) { prefill(p) }
                }
            } label: {
                HStack {
                    Text(prefillProject?.name ?? "Choose a project")
                        .foregroundStyle(prefillProject == nil ? Brand.text2 : Brand.text)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down").font(.footnote).foregroundStyle(Brand.text3)
                }
            }
            .disabled(projects.allSatisfy { !$0.hasGauge })
        }
        .glassCard()
    }

    private var inputCard: some View {
        VStack(spacing: 14) {
            field("Stitches per \(Int(unit.gaugeSpan)) \(unit.shortUnit)", $stitchesText)
            field("Rows per \(Int(unit.gaugeSpan)) \(unit.shortUnit)", $rowsText)
            Divider().overlay(Brand.hairline)
            field("Target width (\(unit.shortUnit))", $widthText)
            field("Target length (\(unit.shortUnit))", $lengthText)
        }
        .glassCard()
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Result")
            if hasResult {
                HStack(spacing: 10) {
                    StatTile(value: castOn > 0 ? "\(castOn)" : "—", label: "Cast on (sts)", tint: Brand.live)
                    StatTile(value: rowCount > 0 ? "\(rowCount)" : "—", label: "Rows")
                }
                if castOn > 0, gaugeSts > 0 {
                    let finished = GaugeMath.widthInches(gaugeStitchesPer4in: gaugeSts, stitches: castOn)
                    Text("\(castOn) stitches measures about \(format(GaugeMath.display(inches: finished, unit: unit))) \(unit.shortUnit) wide at this gauge.")
                        .font(.footnote).foregroundStyle(Brand.text2)
                }
            } else {
                Text("Enter your gauge and a target size to see the numbers.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            }
        }
        .glassCard()
    }

    private func field(_ label: String, _ binding: Binding<String>) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Brand.text)
            Spacer()
            TextField("0", text: binding).keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing).frame(width: 90)
                .font(Brand.mono(16))
        }
    }

    private func prefill(_ p: Project) {
        prefillProject = p
        stitchesText = trim(p.gaugeStitches)
        rowsText = trim(p.gaugeRows)
        Haptics.selection()
    }
    private func parse(_ s: String) -> Double { max(0, Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0) }
    private func trim(_ d: Double) -> String { d == d.rounded() ? String(Int(d)) : String(d) }
    private func format(_ d: Double) -> String { String(format: "%.1f", d) }
}
