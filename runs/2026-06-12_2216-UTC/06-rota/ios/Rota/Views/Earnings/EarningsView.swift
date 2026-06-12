import SwiftUI
import SwiftData
import Charts

private struct WeekEarning: Identifiable {
    let id: Int          // week index within month
    let label: String
    let earnings: Double
}

private struct TypeSlice: Identifiable {
    let id: String       // type name
    let hours: Double
    let earnings: Double
    let colorHex: String
}

struct EarningsView: View {
    @Query private var patterns: [RotationPattern]
    @Query private var overrides: [ShiftOverride]
    @AppStorage("currencySymbol") private var currencySymbol = "$"

    @State private var monthAnchor = Date.now

    private var activePattern: RotationPattern? {
        patterns.first(where: \.isActive) ?? patterns.first
    }

    private var monthInterval: DateInterval? {
        Calendar.current.dateInterval(of: .month, for: monthAnchor)
    }

    private var summary: RotaEngine.PeriodSummary {
        guard let interval = monthInterval,
              let lastDay = Calendar.current.date(byAdding: .day, value: -1, to: interval.end) else {
            return RotaEngine.PeriodSummary()
        }
        return RotaEngine.summary(from: interval.start, through: lastDay, pattern: activePattern, overrides: overrides)
    }

    private var typeSlices: [TypeSlice] {
        summary.hoursByType.map { name, hours in
            TypeSlice(
                id: name,
                hours: hours,
                earnings: summary.earningsByType[name] ?? 0,
                colorHex: summary.colorByType[name] ?? "8A8F99"
            )
        }
        .sorted { $0.earnings > $1.earnings }
    }

    private var weekEarnings: [WeekEarning] {
        guard let interval = monthInterval else { return [] }
        let calendar = Calendar.current
        var result: [WeekEarning] = []
        var weekStart = interval.start
        var index = 0
        while weekStart < interval.end && index < 6 {
            let weekEnd = min(
                calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart,
                calendar.date(byAdding: .day, value: -1, to: interval.end) ?? weekStart
            )
            let s = RotaEngine.summary(from: weekStart, through: weekEnd, pattern: activePattern, overrides: overrides)
            let label = "\(calendar.component(.day, from: weekStart))–\(calendar.component(.day, from: weekEnd))"
            result.append(WeekEarning(id: index, label: label, earnings: s.earnings))
            guard let next = calendar.date(byAdding: .day, value: 7, to: weekStart) else { break }
            weekStart = next
            index += 1
        }
        return result
    }

    private var hasRates: Bool {
        typeSlices.contains { $0.earnings > 0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    monthPicker
                    if activePattern == nil {
                        ContentUnavailableView(
                            "Nothing to Count Yet",
                            systemImage: "banknote",
                            description: Text("Set up your rotation (with hourly rates on each shift type) and Rota projects hours and pay for any month.")
                        )
                        .frame(minHeight: 280)
                    } else {
                        totals
                        if hasRates {
                            weeklyChart
                        } else {
                            Label("Add an hourly rate to your shift types to see pay estimates — hours are tracked either way.", systemImage: "info.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .rotaPanel()
                        }
                        byTypePanel
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Earnings")
        }
    }

    private var monthPicker: some View {
        HStack {
            Button {
                Haptics.tap()
                if let prev = Calendar.current.date(byAdding: .month, value: -1, to: monthAnchor) {
                    monthAnchor = prev
                }
            } label: {
                Image(systemName: "chevron.left").frame(width: 38, height: 38)
            }
            .accessibilityLabel("Previous month")
            Spacer()
            Text(monthAnchor, format: .dateTime.month(.wide).year())
                .font(.headline)
            Spacer()
            Button {
                Haptics.tap()
                if let next = Calendar.current.date(byAdding: .month, value: 1, to: monthAnchor) {
                    monthAnchor = next
                }
            } label: {
                Image(systemName: "chevron.right").frame(width: 38, height: 38)
            }
            .accessibilityLabel("Next month")
        }
    }

    private var totals: some View {
        HStack(spacing: 12) {
            tile("Shifts", "\(summary.workDays)")
            tile("Paid hours", summary.paidHours.formatted(.number.precision(.fractionLength(0...1))))
            tile("Est. pay", hasRates ? Money.format(summary.earnings, symbol: currencySymbol) : "—")
        }
    }

    private func tile(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) this month")
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pay by Week")
                .font(.headline)
            Chart(weekEarnings) { week in
                BarMark(
                    x: .value("Week", week.label),
                    y: .value("Pay", week.earnings)
                )
                .foregroundStyle(RotaTheme.amber.gradient)
                .cornerRadius(4)
            }
            .frame(height: 170)
            .accessibilityLabel("Bar chart of estimated pay per week this month")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rotaPanel()
    }

    private var byTypePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("By Shift Type")
                .font(.headline)
            if typeSlices.isEmpty {
                Text("No working shifts this month.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                ForEach(typeSlices) { slice in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(hex: slice.colorHex))
                            .frame(width: 10, height: 10)
                            .accessibilityHidden(true)
                        Text(slice.id)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(slice.hours.formatted(.number.precision(.fractionLength(0...1)))) h")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                        if slice.earnings > 0 {
                            Text(Money.format(slice.earnings, symbol: currencySymbol))
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .frame(minWidth: 70, alignment: .trailing)
                        }
                    }
                    .padding(.vertical, 3)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rotaPanel()
    }
}
