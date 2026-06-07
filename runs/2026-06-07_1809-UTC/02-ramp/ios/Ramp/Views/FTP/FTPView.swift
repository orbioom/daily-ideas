import SwiftUI
import SwiftData
import Charts

/// FTP hub: current value + W/kg, history with CRUD, an FTP-over-time chart,
/// the seven Coggan power zones, and a standalone zone calculator.
struct FTPView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FTPEntry.date, order: .reverse) private var entries: [FTPEntry]

    @AppStorage("ramp.weightKg") private var weightKg = 72.0
    @AppStorage("ramp.fallbackFTP") private var fallbackFTP = 250

    @State private var showAdd = false
    @State private var editingEntry: FTPEntry?

    private var currentFTP: Int {
        LoadEngine.ftp(on: Date(), entries: entries, fallback: fallbackFTP)
    }
    private var wkg: Double {
        LoadEngine.wattsPerKg(ftp: currentFTP, weightKg: weightKg)
    }
    private var zones: [LoadEngine.PowerZone] {
        LoadEngine.powerZones(ftp: currentFTP)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    currentCard
                    if entries.count > 1 { historyChartCard }
                    historyCard
                    zonesCard
                    ZoneCalculatorCard(weightKg: weightKg, seedFTP: currentFTP)
                }
                .padding(20)
            }
            .navigationTitle("FTP")
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add an FTP entry")
                }
            }
            .sheet(isPresented: $showAdd) { FTPEditView(entry: nil) }
            .sheet(item: $editingEntry) { e in FTPEditView(entry: e) }
        }
    }

    // MARK: Current

    private var currentCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Current FTP")
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(currentFTP)")
                        .font(Brand.mono(52, weight: .bold))
                        .foregroundStyle(Brand.text)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text("W").font(.title3.weight(.semibold)).foregroundStyle(Brand.text2)
                }
                HStack(spacing: 16) {
                    Badge(text: wkg > 0 ? "\(Format.oneDecimal(wkg)) W/kg" : "set weight",
                          color: Brand.live)
                    if entries.isEmpty {
                        Badge(text: "fallback value", color: Brand.warn)
                    } else if let latest = entries.first {
                        Badge(text: latest.source.label, color: Brand.info)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Current FTP \(currentFTP) watts, \(Format.oneDecimal(wkg)) watts per kilogram.")
        }
    }

    // MARK: History chart

    private var historyChartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: "FTP over time")
                let sorted = entries.sorted { $0.date < $1.date }
                Chart(sorted) { e in
                    LineMark(x: .value("Date", e.date), y: .value("FTP", e.watts))
                        .foregroundStyle(Brand.live)
                        .lineStyle(StrokeStyle(lineWidth: 2.4))
                        .interpolationMethod(.monotone)
                    PointMark(x: .value("Date", e.date), y: .value("FTP", e.watts))
                        .foregroundStyle(Brand.live)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(Brand.hairline)
                        AxisValueLabel().font(Brand.mono(9))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine().foregroundStyle(Brand.hairline.opacity(0.5))
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day()).font(Brand.mono(9))
                    }
                }
                .frame(height: 150)
                .accessibilityLabel("FTP over time")
                .accessibilityValue(ftpTrendSummary)
            }
        }
    }

    private var ftpTrendSummary: String {
        let sorted = entries.sorted { $0.date < $1.date }
        guard let first = sorted.first, let last = sorted.last else { return "No data" }
        let delta = last.watts - first.watts
        let sign = delta >= 0 ? "up" : "down"
        return "From \(first.watts) to \(last.watts) watts, \(sign) \(abs(delta)) watts across \(sorted.count) tests."
    }

    // MARK: History list

    private var historyCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle(text: "History")
                if entries.isEmpty {
                    EmptyStateView(icon: "bolt.slash",
                                   title: "No FTP recorded",
                                   message: "Add a test or estimate. Ramp uses your settings fallback until then.")
                        .padding(.vertical, 8)
                } else {
                    ForEach(entries) { e in
                        Button { Haptics.tap(); editingEntry = e } label: {
                            ftpRow(e)
                        }
                        .buttonStyle(.plain)
                        if e.id != entries.last?.id {
                            Divider().overlay(Brand.hairline)
                        }
                    }
                }
            }
        }
    }

    private func ftpRow(_ e: FTPEntry) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(e.watts) W")
                    .font(Brand.mono(17, weight: .semibold))
                    .foregroundStyle(Brand.text)
                Text("\(e.source.label) · \(Format.shortDate.string(from: e.date))")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            Spacer()
            if weightKg > 0 {
                Text("\(Format.oneDecimal(LoadEngine.wattsPerKg(ftp: e.watts, weightKg: weightKg))) W/kg")
                    .font(Brand.mono(12)).foregroundStyle(Brand.text2)
            }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Brand.text3)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(e.watts) watts, \(e.source.label), \(Format.shortDate.string(from: e.date))")
    }

    // MARK: Zones table

    private var zonesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: "Power zones · from \(currentFTP) W")
                if zones.isEmpty {
                    Text("Set an FTP to compute your zones.")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                } else {
                    ForEach(zones) { z in
                        ZoneRow(zone: z)
                        if z.id != zones.last?.id { Divider().overlay(Brand.hairline) }
                    }
                }
            }
        }
    }
}

/// One row in the power-zone table.
struct ZoneRow: View {
    let zone: LoadEngine.PowerZone
    var body: some View {
        HStack(spacing: 12) {
            Text("Z\(zone.number)")
                .font(Brand.mono(13, weight: .bold))
                .foregroundStyle(LoadEngine.zoneColor(zone.number))
                .frame(width: 30, alignment: .leading)
            VStack(alignment: .leading, spacing: 1) {
                Text(zone.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Text(zone.pctLabel).font(Brand.mono(10)).foregroundStyle(Brand.text3)
            }
            Spacer()
            Text(zone.wattLabel)
                .font(Brand.mono(13, weight: .medium))
                .foregroundStyle(Brand.text2)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Zone \(zone.number) \(zone.name), \(zone.pctLabel), \(zone.wattLabel)")
    }
}

/// A standalone calculator: enter any FTP to preview its zones and W/kg.
struct ZoneCalculatorCard: View {
    let weightKg: Double
    let seedFTP: Int

    @State private var ftpText: String = ""

    private var ftp: Int { Int(ftpText) ?? 0 }
    private var zones: [LoadEngine.PowerZone] { LoadEngine.powerZones(ftp: ftp) }
    private var wkg: Double { LoadEngine.wattsPerKg(ftp: ftp, weightKg: weightKg) }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "Zone calculator")
                HStack {
                    Text("Try an FTP").foregroundStyle(Brand.text2)
                    Spacer()
                    TextField("watts", text: $ftpText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                        .font(Brand.mono(16))
                        .accessibilityLabel("FTP to calculate, in watts")
                    Text("W").foregroundStyle(Brand.text3)
                }
                if ftp > 0 {
                    if weightKg > 0 {
                        InfoRow(label: "Power-to-weight", value: "\(Format.oneDecimal(wkg)) W/kg", mono: true)
                    }
                    ForEach(zones) { z in
                        ZoneRow(zone: z)
                        if z.id != zones.last?.id { Divider().overlay(Brand.hairline) }
                    }
                } else {
                    Text("Enter a number to see the seven zones in watts.")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
            }
        }
        .onAppear { if ftpText.isEmpty && seedFTP > 0 { ftpText = String(seedFTP) } }
    }
}
