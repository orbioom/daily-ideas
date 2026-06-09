import SwiftUI
import SwiftData

struct ReportView: View {
    @Query(sort: \VitalEntry.date, order: .reverse) private var entries: [VitalEntry]

    @AppStorage("cuff.weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage("cuff.glucoseUnit") private var glucoseUnitRaw = GlucoseUnit.mgdl.rawValue
    @AppStorage("cuff.targetSystolic") private var targetSystolic = 120
    @AppStorage("cuff.targetDiastolic") private var targetDiastolic = 80

    @State private var range = 30

    private var weightUnit: WeightUnit { WeightUnit.from(weightUnitRaw) }
    private var glucoseUnit: GlucoseUnit { GlucoseUnit.from(glucoseUnitRaw) }

    private var ranged: [VitalEntry] {
        VitalsEngine.within(entries, days: range)
    }
    private var bp: [VitalEntry] { ranged.filter { $0.kind == .bloodPressure } }

    private var csvText: String {
        ReportBuilder.csv(ranged, weight: weightUnit, glucose: glucoseUnit)
    }
    private var summaryText: String {
        ReportBuilder.textSummary(ranged, weight: weightUnit, glucose: glucoseUnit,
                                  targetSystolic: targetSystolic, targetDiastolic: targetDiastolic)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if entries.isEmpty {
                    EmptyStateView(icon: "doc.text",
                                   title: "Nothing to report yet",
                                   message: "Log some readings and you can export a clean summary for your clinician here.")
                        .glassCard()
                        .padding(20)
                } else {
                    VStack(spacing: 18) {
                        rangePicker
                        summaryCard
                        exportCard
                        previewCard
                    }
                    .padding(20)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Report")
        }
    }

    private var rangePicker: some View {
        Picker("Range", selection: $range) {
            Text("7 days").tag(7)
            Text("30 days").tag(30)
            Text("90 days").tag(90)
        }
        .pickerStyle(.segmented)
        .onChange(of: range) { _, _ in Haptics.selection() }
    }

    @ViewBuilder private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Last \(range) days")
                Spacer()
                Text("\(ranged.count) reading\(ranged.count == 1 ? "" : "s")")
                    .font(Brand.mono(12)).foregroundStyle(Brand.text3)
            }
            if let avg = VitalsEngine.bpAverage(bp) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatTile(value: "\(avg.systolic)/\(avg.diastolic)", label: "Avg BP", tint: avg.category.color)
                    StatTile(value: avg.category.label, label: "Stage", tint: avg.category.color)
                    if let pct = VitalsEngine.bpInTargetFraction(bp, targetSystolic: targetSystolic, targetDiastolic: targetDiastolic) {
                        StatTile(value: "\(Int((pct * 100).rounded()))%", label: "In target")
                    }
                    if let mm = VitalsEngine.minMaxSystolic(bp) {
                        StatTile(value: "\(mm.min)–\(mm.max)", label: "Sys range")
                    }
                }
            } else {
                Text("No blood-pressure readings in this range.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            }

            // Other metric averages.
            ForEach([VitalKind.weight, .glucose, .spo2, .pulse]) { kind in
                let xs = ranged.filter { $0.kind == kind }
                if let avg = VitalsEngine.averageValue(xs) {
                    HStack {
                        Image(systemName: kind.symbol).foregroundStyle(kind.tint).frame(width: 22)
                            .accessibilityHidden(true)
                        Text(kind.label).foregroundStyle(Brand.text2)
                        Spacer()
                        Text("\(Format.averageValue(avg, kind: kind, weight: weightUnit, glucose: glucoseUnit)) avg")
                            .font(Brand.mono(13, weight: .medium)).foregroundStyle(Brand.text)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .glassCard()
    }

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Share with your clinician")
            ShareLink(item: summaryText,
                      preview: SharePreview("Cuff vitals summary")) {
                Label("Share text summary", systemImage: "doc.text")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyle())
            .disabled(ranged.isEmpty)

            ShareLink(item: csvText,
                      preview: SharePreview("Cuff vitals CSV")) {
                Label("Share CSV", systemImage: "tablecells")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(InkButtonStyle())
            .disabled(ranged.isEmpty)

            Text("Generates a plain-text or spreadsheet-ready file. Nothing leaves your device until you share it.")
                .font(.caption).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Preview")
            Text(summaryText)
                .font(Brand.mono(11))
                .foregroundStyle(Brand.text2)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Report preview")
    }
}
