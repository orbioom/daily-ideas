import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \DrinkEntry.date, order: .reverse) private var entries: [DrinkEntry]
    @Query private var goals: [DrinkGoal]

    private var goal: DrinkGoal? { goals.first }
    private var weekData: [(day: String, drinks: Double)] { DripEngine.weeklyDrinksByDay(entries: entries) }
    private var contexts: [(context: String, drinks: Double)] { DripEngine.contextBreakdown(entries: entries) }
    private var moneySaved: Double { goal.map { DripEngine.moneySavedThisWeek(entries: entries, goal: $0) } ?? 0 }
    private var currencySymbol: String { goal?.currencySymbol ?? "$" }
    private var afDays: Int { DripEngine.alcoholFreeDaysThisWeek(entries: entries) }
    private var afTarget: Int { goal?.alcoholFreeDaysTarget ?? 3 }

    var body: some View {
        NavigationStack {
            ScrollView {
                if entries.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(DripTheme.accent.opacity(0.3))
                            .accessibilityHidden(true)
                        Text("No data yet")
                            .font(.headline).foregroundStyle(DripTheme.text)
                        Text("Log drinks to see your insights.")
                            .foregroundStyle(DripTheme.subtle)
                    }
                    .frame(maxWidth: .infinity, minHeight: 400)
                } else {
                    VStack(spacing: 20) {
                        statsRow
                        weekChart
                        if !contexts.isEmpty { contextBreakdown }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80)
                }
            }
            .background(DripTheme.bg)
            .navigationTitle("Insights")
        }
    }

    @ViewBuilder
    private var statsRow: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            InsightCard(value: "\(afDays)/\(afTarget)", label: "AF Days This Week", icon: "moon.stars.fill",
                       color: afDays >= afTarget ? DripTheme.safe : DripTheme.warning)
            InsightCard(value: "\(currencySymbol)\(String(format: "%.0f", moneySaved))",
                       label: "Saved This Week", icon: "dollarsign.circle.fill", color: DripTheme.safe)
            InsightCard(value: String(format: "%.1f", DripEngine.weekDrinks(entries: entries)),
                       label: "Drinks This Week", icon: "drop.fill", color: DripTheme.accent)
            InsightCard(value: String(format: "%.0f", entries.reduce(0) { $0 + $1.costAmount }),
                       label: "\(currencySymbol) Spent (total)", icon: "creditcard.fill", color: DripTheme.subtle)
        }
    }

    @ViewBuilder
    private var weekChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week's Drinks")
                .font(.headline).foregroundStyle(DripTheme.text)
            Chart(weekData, id: \.day) { item in
                BarMark(x: .value("Day", item.day), y: .value("Drinks", item.drinks))
                    .foregroundStyle(DripTheme.accent.gradient)
                    .cornerRadius(6)
            }
            .frame(height: 160)
        }
        .padding()
        .background(DripTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var contextBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Context")
                .font(.headline).foregroundStyle(DripTheme.text)
            ForEach(contexts.prefix(5), id: \.context) { item in
                HStack {
                    Text(DrinkContext(rawValue: item.context)?.emoji ?? "📍")
                        .font(.title3).accessibilityHidden(true)
                    Text(item.context)
                        .font(.subheadline).foregroundStyle(DripTheme.text)
                    Spacer()
                    Text(String(format: "%.1f std", item.drinks))
                        .font(.caption.weight(.medium)).foregroundStyle(DripTheme.subtle)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(item.context): \(String(format: "%.1f", item.drinks)) standard drinks")
            }
        }
        .padding()
        .background(DripTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct InsightCard: View {
    let value: String; let label: String; let icon: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.title3).foregroundStyle(color).accessibilityHidden(true)
            Text(value).font(.title2.weight(.bold)).foregroundStyle(DripTheme.text)
            Text(label).font(.caption).foregroundStyle(DripTheme.subtle)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding()
        .background(DripTheme.card, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
