import SwiftUI
import SwiftData
import Charts

struct CalendarInsightsView: View {
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \Subscription.createdAt, order: .reverse) private var subscriptions: [Subscription]

    @AppStorage(PrefKey.currencyCode) private var currencyCode: String = PrefDefault.currencyCode
    @AppStorage(PrefKey.hideAmounts) private var hideAmounts: Bool = false
    @AppStorage(PrefKey.includeTrialsInTotal) private var includeTrials: Bool = false
    @AppStorage(PrefKey.firstWeekday) private var firstWeekday: Int = PrefDefault.firstWeekday
    @AppStorage(PrefKey.isPro) private var isPro: Bool = false

    @State private var visibleMonth: Date = Date()
    @State private var selectedDay: Date?
    @State private var showPaywall = false

    private var calendar: Calendar {
        var c = Calendar.current
        c.firstWeekday = firstWeekday
        return c
    }

    private var summary: SummaryEngine {
        SummaryEngine(subscriptions: subscriptions, includeTrialsInTotal: includeTrials, calendar: calendar)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RecurTheme.appBackground(scheme).ignoresSafeArea()
                if subscriptions.isEmpty {
                    ScrollView {
                        EmptyStateView(symbol: "calendar.badge.exclamationmark",
                                       title: "Nothing to chart yet",
                                       message: "Add subscriptions to see your renewal calendar and spending insights.")
                            .padding(.top, 60)
                    }
                } else {
                    content
                }
            }
            .navigationTitle("Insights")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                calendarCard
                if isPro {
                    categoryBarCard
                    cycleBarCard
                    trendCard
                } else {
                    proInsightsLock
                }
                Color.clear.frame(height: 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Calendar

    private var monthRenewals: [Date: [UpcomingRenewal]] {
        summary.renewalDays(inMonthOf: visibleMonth, calendar: calendar)
    }

    private var calendarCard: some View {
        RecurCard {
            VStack(alignment: .leading, spacing: 14) {
                monthHeader
                MonthGrid(monthDate: visibleMonth,
                          calendar: calendar,
                          renewalsByDay: monthRenewals,
                          selectedDay: $selectedDay)
                if let day = selectedDay {
                    daySection(day)
                }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                if let prev = calendar.date(byAdding: .month, value: -1, to: visibleMonth) {
                    visibleMonth = prev; selectedDay = nil; Haptics.selection()
                }
            } label: { Image(systemName: "chevron.left") }
                .accessibilityLabel("Previous month")
            Spacer()
            Text(monthTitle)
                .font(.headline)
                .foregroundStyle(RecurTheme.primaryText(scheme))
            Spacer()
            Button {
                if let next = calendar.date(byAdding: .month, value: 1, to: visibleMonth) {
                    visibleMonth = next; selectedDay = nil; Haptics.selection()
                }
            } label: { Image(systemName: "chevron.right") }
                .accessibilityLabel("Next month")
        }
        .foregroundStyle(RecurTheme.violet)
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: visibleMonth)
    }

    @ViewBuilder
    private func daySection(_ day: Date) -> some View {
        let key = calendar.startOfDay(for: day)
        let items = monthRenewals[key] ?? []
        VStack(alignment: .leading, spacing: 8) {
            Divider().overlay(RecurTheme.hairline(scheme))
            Text(DateText.medium(day))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RecurTheme.primaryText(scheme))
            if items.isEmpty {
                Text("No renewals on this day.")
                    .font(.caption)
                    .foregroundStyle(RecurTheme.secondaryText(scheme))
            } else {
                ForEach(items) { item in
                    HStack(spacing: 10) {
                        CategoryDot(colorHex: item.subscription.colorHex)
                        Text(item.subscription.name)
                            .font(.subheadline)
                            .foregroundStyle(RecurTheme.primaryText(scheme))
                        Spacer()
                        MoneyText(value: item.subscription.costDecimal, code: currencyCode, hidden: hideAmounts)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RecurTheme.primaryText(scheme))
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    // MARK: - Insights (Pro)

    private var categoryBarCard: some View {
        let slices = summary.byCategory()
        return RecurCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Monthly spend by category", systemImage: "chart.bar")
                if slices.isEmpty {
                    Text("No active spend to chart.")
                        .font(.subheadline).foregroundStyle(RecurTheme.secondaryText(scheme))
                } else {
                    Chart(slices) { slice in
                        BarMark(
                            x: .value("Spend", doubleVal(slice.monthlyTotal)),
                            y: .value("Category", slice.label)
                        )
                        .foregroundStyle(Color(hex: slice.colorHex))
                        .cornerRadius(5)
                    }
                    .frame(height: CGFloat(max(120, slices.count * 38)))
                    .chartXAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let d = value.as(Double.self) {
                                    Text(hideAmounts ? "•" : MoneyFormatter.compact(Decimal(d), code: currencyCode))
                                }
                            }
                        }
                    }
                    .accessibilityLabel("Monthly spend by category bar chart")
                    .accessibilityValue(slices.map { "\($0.label) \(MoneyFormatter.string($0.monthlyTotal, code: currencyCode))" }.joined(separator: ", "))
                }
            }
        }
    }

    private var cycleBarCard: some View {
        let slices = summary.byCycle()
        return RecurCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Monthly spend by billing cycle", systemImage: "arrow.triangle.2.circlepath")
                if slices.isEmpty {
                    Text("No active spend to chart.")
                        .font(.subheadline).foregroundStyle(RecurTheme.secondaryText(scheme))
                } else {
                    Chart(slices) { slice in
                        BarMark(
                            x: .value("Cycle", slice.label),
                            y: .value("Spend", doubleVal(slice.monthlyTotal))
                        )
                        .foregroundStyle(Color(hex: slice.colorHex))
                        .cornerRadius(5)
                    }
                    .frame(height: 180)
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let d = value.as(Double.self) {
                                    Text(hideAmounts ? "•" : MoneyFormatter.compact(Decimal(d), code: currencyCode))
                                }
                            }
                        }
                    }
                    .accessibilityLabel("Monthly spend by billing cycle bar chart")
                }
            }
        }
    }

    /// A simple 6-month projection trend (flat monthly total) shown as bars.
    private var trendCard: some View {
        let monthly = summary.monthlyTotal
        let points = trendPoints(monthly: monthly)
        return RecurCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Projected spend (next 6 months)", systemImage: "chart.line.uptrend.xyaxis")
                Chart {
                    ForEach(points, id: \.label) { point in
                        BarMark(x: .value("Month", point.label), y: .value("Spend", point.value))
                            .foregroundStyle(RecurTheme.violet.gradient)
                            .cornerRadius(5)
                    }
                }
                .frame(height: 170)
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let d = value.as(Double.self) {
                                Text(hideAmounts ? "•" : MoneyFormatter.compact(Decimal(d), code: currencyCode))
                            }
                        }
                    }
                }
                .accessibilityLabel("Projected monthly spend over the next six months")
                HStack {
                    Text("Cumulative:")
                        .font(.caption).foregroundStyle(RecurTheme.secondaryText(scheme))
                    Spacer()
                    Text(hideAmounts ? MoneyFormatter.masked(code: currencyCode)
                                     : MoneyFormatter.string(monthly * 6, code: currencyCode))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RecurTheme.primaryText(scheme))
                }
            }
        }
    }

    private func trendPoints(monthly: Decimal) -> [(label: String, value: Double)] {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        var result: [(String, Double)] = []
        let base = doubleVal(monthly)
        for i in 0..<6 {
            if let date = calendar.date(byAdding: .month, value: i, to: Date()) {
                result.append((f.string(from: date), base))
            }
        }
        return result.map { (label: $0.0, value: $0.1) }
    }

    private var proInsightsLock: some View {
        RecurCard {
            VStack(spacing: 12) {
                HStack { SectionHeader(title: "Full insights", systemImage: "chart.bar.xaxis"); ProBadge() }
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 40))
                    .foregroundStyle(RecurTheme.violet.opacity(0.7))
                    .accessibilityHidden(true)
                Text("Spend by category and cycle, plus a spending trend — unlock with Recur Pro.")
                    .font(.subheadline)
                    .foregroundStyle(RecurTheme.secondaryText(scheme))
                    .multilineTextAlignment(.center)
                Button("Unlock Recur Pro") { showPaywall = true }
                    .buttonStyle(RecurPrimaryButtonStyle())
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func doubleVal(_ d: Decimal) -> Double {
        NSDecimalNumber(decimal: d).doubleValue
    }
}
