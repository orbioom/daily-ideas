import SwiftUI
import SwiftData
import Charts
import UIKit

struct ReportsView: View {
    @Query(sort: \TimeEntry.start, order: .reverse) private var entries: [TimeEntry]
    @AppStorage("defaultCurrency") private var currency = Locale.current.currency?.identifier ?? "USD"
    @AppStorage("roundingRule") private var roundingRaw = RoundingRule.none.rawValue

    @State private var range = ReportRange.thisWeek
    @State private var copied = false

    private let engine = TimeEngine()
    private var rounding: RoundingRule { RoundingRule(rawValue: roundingRaw) ?? .none }

    enum ReportRange: String, CaseIterable, Identifiable {
        case thisWeek = "This Week", lastWeek = "Last Week", thisMonth = "This Month"
        var id: String { rawValue }
    }

    private var interval: DateInterval {
        switch range {
        case .thisWeek: return engine.weekInterval(containing: .now)
        case .lastWeek:
            let lastWeekDate = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
            return engine.weekInterval(containing: lastWeekDate)
        case .thisMonth: return engine.monthInterval(containing: .now)
        }
    }

    private var scoped: [TimeEntry] { engine.entries(entries, in: interval) }
    private var byProject: [TimeEngine.ProjectTotal] { engine.byProject(scoped) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if entries.isEmpty {
                    EmptyStateView(
                        icon: "chart.pie",
                        title: "No reports yet",
                        message: "Track some time and you'll get clean weekly and monthly summaries you can copy into an invoice."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            rangePicker
                            totalsCard
                            if scoped.isEmpty {
                                Text("No time tracked in this period.")
                                    .font(.subheadline).foregroundStyle(Brand.text3)
                                    .frame(maxWidth: .infinity).padding(.vertical, 24).glassCard()
                            } else {
                                projectChartCard
                                dailyChartCard
                                copyCard
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Reports")
        }
    }

    private var rangePicker: some View {
        Picker("Range", selection: $range) {
            ForEach(ReportRange.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
    }

    private var totalSeconds: TimeInterval {
        engine.rounded(engine.totalSeconds(scoped), rule: rounding)
    }

    private var totalsCard: some View {
        let billable = scoped.filter { $0.project?.billable ?? false }
        let earnings = engine.totalEarnings(scoped)
        return HStack(spacing: 12) {
            totalTile(DurationFormat.compact(totalSeconds), "tracked", "clock.fill")
            totalTile(DurationFormat.compact(engine.totalSeconds(billable)), "billable", "checkmark.seal.fill")
            totalTile(Money.compact(earnings, code: currency), "earned", "dollarsign.circle.fill")
        }
    }

    private func totalTile(_ value: String, _ label: String, _ symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.title3).foregroundStyle(Color.accentColor)
            Text(value).font(.system(.headline, design: .rounded)).foregroundStyle(Brand.text)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity).glassCard(padding: 14)
        .accessibilityElement(children: .combine).accessibilityLabel("\(value) \(label)")
    }

    private var projectChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By project").font(.headline).foregroundStyle(Brand.text)
            Chart(byProject) { p in
                SectorMark(angle: .value("Hours", p.seconds / 3600), innerRadius: .ratio(0.6), angularInset: 1.5)
                    .foregroundStyle(Color(hex: p.colorHex)).cornerRadius(3)
            }
            .frame(height: 170)
            ForEach(byProject) { p in
                HStack(spacing: 8) {
                    Circle().fill(Color(hex: p.colorHex)).frame(width: 9, height: 9)
                    Text(p.projectName).font(.subheadline).foregroundStyle(Brand.text2).lineLimit(1)
                    Spacer()
                    Text(DurationFormat.compact(p.seconds))
                        .font(Brand.mono(12, weight: .medium)).foregroundStyle(Brand.text)
                    if p.earnings > 0 {
                        Text(Money.compact(p.earnings, code: currency))
                            .font(Brand.mono(11)).foregroundStyle(Brand.live)
                    }
                }
            }
        }
        .glassCard()
    }

    private var dailyChartCard: some View {
        let daily = engine.dailySeconds(scoped, in: interval)
        return VStack(alignment: .leading, spacing: 10) {
            Text("By day").font(.headline).foregroundStyle(Brand.text)
            Chart(daily) { d in
                BarMark(x: .value("Day", d.day, unit: .day),
                        y: .value("Hours", d.seconds / 3600))
                    .foregroundStyle(Color.accentColor.gradient).cornerRadius(4)
            }
            .frame(height: 160)
        }
        .glassCard()
    }

    private var copyCard: some View {
        VStack(spacing: 10) {
            Button {
                UIPasteboard.general.string = reportText()
                Haptics.success()
                withAnimation { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { withAnimation { copied = false } }
            } label: {
                Label(copied ? "Copied!" : "Copy summary", systemImage: copied ? "checkmark" : "doc.on.doc")
            }
            .buttonStyle(InkButtonStyle())
            Text("An invoice-ready text summary for \(range.rawValue.lowercased()).")
                .font(.caption).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    private func reportText() -> String {
        var lines: [String] = []
        lines.append("Time Report — \(range.rawValue)")
        lines.append("\(Format.shortDate.string(from: interval.start)) – \(Format.shortDate.string(from: interval.end.addingTimeInterval(-1)))")
        lines.append("")
        for p in byProject {
            var line = "• \(p.projectName): \(DurationFormat.decimalHours(p.seconds))"
            if p.earnings > 0 { line += " — \(Money.string(p.earnings, code: currency))" }
            lines.append(line)
        }
        lines.append("")
        lines.append("Total: \(DurationFormat.decimalHours(totalSeconds))")
        let earnings = engine.totalEarnings(scoped)
        if earnings > 0 { lines.append("Billable: \(Money.string(earnings, code: currency))") }
        return lines.joined(separator: "\n")
    }
}
