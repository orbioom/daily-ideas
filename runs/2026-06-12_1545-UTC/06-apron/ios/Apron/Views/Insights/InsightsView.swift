import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \Job.createdAt) private var jobs: [Job]
    @AppStorage("taxRate") private var taxRate = 0.0

    private var shifts: [Shift] { jobs.flatMap(\.shifts) }
    private var summary: EarningsSummary { EarningsEngine.summarize(shifts) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                if shifts.isEmpty {
                    EmptyStateView(symbol: "chart.bar",
                                   title: "No insights yet",
                                   message: "Log a few shifts and your trends, best days and real hourly rate will appear here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statGrid
                            trendCard
                            weekdayCard
                            projectionCard
                            if jobs.filter({ !$0.shifts.isEmpty }).count > 1 { byJobCard }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statTile(Currency.string(summary.total), "All-time earned")
            statTile(summary.hours > 0 ? Currency.string(summary.effectiveHourly) + "/h" : "—", "Real hourly rate", Theme.accent)
            statTile(Currency.string(summary.avgPerShift), "Avg per shift")
            statTile(bestDayText, "Best day", Theme.wage)
        }
    }

    private var bestDayText: String {
        guard let best = EarningsEngine.bestWeekday(shifts) else { return "—" }
        return Fmt.shortWeekday(best.weekday)
    }

    private func statTile(_ value: String, _ label: String, _ tint: Color = Theme.textPrimary) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(.title3, design: .rounded).weight(.bold)).foregroundStyle(tint)
                .minimumScaleFactor(0.5).lineLimit(1)
            Text(label).font(.caption).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity).apronCard()
        .accessibilityElement(children: .combine).accessibilityLabel("\(label): \(value)")
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Earnings — last 30 days").font(.headline).foregroundStyle(Theme.textPrimary)
            Chart(EarningsEngine.dailySeries(shifts, days: 30)) { item in
                BarMark(x: .value("Day", item.day, unit: .day), y: .value("Earned", item.total))
                    .foregroundStyle(Theme.heroGradient)
                    .cornerRadius(2)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 180)
            .accessibilityLabel("Bar chart of daily earnings over the last thirty days")
        }
        .apronCard()
    }

    private var weekdayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Average by weekday").font(.headline).foregroundStyle(Theme.textPrimary)
            Chart(EarningsEngine.byWeekday(shifts)) { item in
                BarMark(x: .value("Day", Fmt.shortWeekday(item.weekday)),
                        y: .value("Average", item.avg))
                .foregroundStyle(Theme.accent)
                .cornerRadius(5)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 170)
            .accessibilityLabel("Average earnings by day of week")
        }
        .apronCard()
    }

    private var projectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This month").font(.headline).foregroundStyle(Theme.textPrimary)
            let monthShifts = EarningsEngine.shifts(shifts, in: .month)
            let monthSummary = EarningsEngine.summarize(monthShifts)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Earned so far").font(.caption).foregroundStyle(Theme.textSecondary)
                    Text(Currency.string(monthSummary.total)).font(.title3.weight(.bold)).foregroundStyle(Theme.textPrimary)
                }
                Spacer()
                if let proj = EarningsEngine.monthProjection(shifts) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Projected total").font(.caption).foregroundStyle(Theme.textSecondary)
                        Text(Currency.string(proj)).font(.title3.weight(.bold)).foregroundStyle(Theme.accent)
                    }
                }
            }
            if taxRate > 0 {
                Divider().overlay(Theme.track)
                HStack {
                    Text("Suggested tax set-aside (\(Fmt.percent(taxRate)))").font(.caption).foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(Currency.string(EarningsEngine.taxSetAside(monthSummary.total, rate: taxRate)))
                        .font(.caption.weight(.semibold)).foregroundStyle(Theme.wage)
                }
            }
        }
        .apronCard()
    }

    private var byJobCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By job").font(.headline).foregroundStyle(Theme.textPrimary)
            ForEach(jobs.filter { !$0.shifts.isEmpty }) { job in
                let s = EarningsEngine.summarize(job.shifts)
                HStack {
                    Circle().fill(job.tint).frame(width: 10, height: 10)
                    Text(job.name).font(.subheadline).foregroundStyle(Theme.textPrimary).lineLimit(1)
                    Spacer()
                    Text(Currency.string(s.total)).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                    Text(s.hours > 0 ? "(\(Currency.string(s.effectiveHourly))/h)" : "")
                        .font(.caption).foregroundStyle(Theme.accent)
                }
                .padding(.vertical, 3)
            }
        }
        .apronCard()
    }
}
