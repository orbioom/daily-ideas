import SwiftUI
import SwiftData
import Charts

struct TrendsView: View {
    @Query(sort: \Account.sortIndex) private var accounts: [Account]
    @Query private var entries: [BalanceEntry]
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("netWorthGoal") private var goal = 0.0

    @State private var rangeMonths = 12
    @State private var showGoalEditor = false

    private var series: [NetWorthPoint] {
        NetWorthEngine.monthlySeries(accounts: accounts, entries: entries, months: rangeMonths)
    }
    private var fullSeries: [NetWorthPoint] {
        NetWorthEngine.monthlySeries(accounts: accounts, entries: entries, months: 24)
    }
    private var current: Double { NetWorthEngine.totals(accounts).net }
    private var avgChange: Double? { NetWorthEngine.averageMonthlyChange(fullSeries) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if series.count < 2 {
                    EmptyStateView(icon: "calendar",
                                   title: "Not enough history yet",
                                   message: "Update your balances over a couple of months and your net-worth trend and growth rate will appear here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            rangePicker
                            chartCard
                            goalCard
                            tableCard
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Trends")
            .sheet(isPresented: $showGoalEditor) { GoalEditor(goal: $goal) }
        }
    }

    private var rangePicker: some View {
        Picker("Range", selection: $rangeMonths) {
            Text("6M").tag(6); Text("1Y").tag(12); Text("2Y").tag(24)
        }
        .pickerStyle(.segmented)
    }

    private var chartCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Net worth").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                Chart(series) { pt in
                    AreaMark(x: .value("Month", pt.date), y: .value("Net", pt.net))
                        .foregroundStyle(LinearGradient(colors: [Theme.accent.opacity(0.32), Theme.accent.opacity(0.03)],
                                                        startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Month", pt.date), y: .value("Net", pt.net))
                        .foregroundStyle(Theme.accent).interpolationMethod(.monotone)
                    if goal > 0 {
                        RuleMark(y: .value("Goal", goal))
                            .foregroundStyle(Theme.good.opacity(0.7))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel { if let v = value.as(Double.self) { Text(Money.compact(v, code: currencyCode)) } }
                    }
                }
                .frame(height: 200)
            }
        }
    }

    private var goalCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Goal").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                    Spacer()
                    Button(goal > 0 ? "Edit" : "Set goal") { showGoalEditor = true }
                        .font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.accent)
                }
                if goal > 0 {
                    let frac = max(0, min(1, current / goal))
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.surfaceAlt)
                            Capsule().fill(Theme.good).frame(width: frac * geo.size.width)
                        }
                    }
                    .frame(height: 12)
                    HStack {
                        Text("\(Money.compact(current, code: currencyCode)) of \(Money.compact(goal, code: currencyCode))")
                            .font(Theme.rounded(13, .medium)).foregroundStyle(Theme.inkSoft)
                        Spacer()
                        Text("\(Int(frac * 100))%").font(Theme.rounded(13, .bold)).foregroundStyle(Theme.good)
                    }
                    if let months = NetWorthEngine.monthsToGoal(current: current, goal: goal, monthlyChange: avgChange),
                       let date = Calendar.current.date(byAdding: .month, value: months, to: Date()) {
                        Text("On track to reach it by \(Fmt.monthYear(date)) at your recent pace.")
                            .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                    } else if current >= goal {
                        Text("Goal reached — set a new one! 🎉")
                            .font(Theme.rounded(13, .bold)).foregroundStyle(Theme.good)
                    } else {
                        Text("Keep updating balances to project a date.")
                            .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                    }
                } else {
                    Text("Set a target net worth to track your progress toward it.")
                        .font(Theme.rounded(14, .regular)).foregroundStyle(Theme.inkSoft)
                }
            }
        }
    }

    private var tableCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Month by month").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                let pts = series.reversed().map { $0 }
                ForEach(Array(pts.enumerated()), id: \.element.id) { idx, pt in
                    let prevIdx = idx + 1
                    let delta: Double? = prevIdx < pts.count ? pt.net - pts[prevIdx].net : nil
                    HStack {
                        Text(Fmt.monthYear(pt.date)).font(Theme.rounded(14, .medium)).foregroundStyle(Theme.inkSoft)
                        Spacer()
                        Text(Money.format(pt.net, code: currencyCode, fraction: false))
                            .font(Theme.rounded(14, .bold)).foregroundStyle(Theme.ink)
                        if let delta { DeltaBadge(amount: delta, currency: currencyCode) }
                    }
                    .padding(.vertical, 5)
                    if idx < pts.count - 1 { Divider().background(Theme.hairline) }
                }
            }
        }
    }
}

struct GoalEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var goal: Double
    @State private var text = ""
    @AppStorage("currencyCode") private var currencyCode = "USD"

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    Section("Target net worth") {
                        HStack {
                            TextField("0", text: $text).keyboardType(.decimalPad)
                            Text(currencyCode).foregroundStyle(Theme.inkSoft)
                        }
                    }
                    if goal > 0 {
                        Section {
                            Button("Remove goal", role: .destructive) { goal = 0; dismiss() }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Net worth goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { goal = max(0, Double(text) ?? 0); dismiss() }
                        .disabled((Double(text) ?? 0) <= 0).bold()
                }
            }
            .onAppear { if goal > 0 { text = String(Int(goal)) } }
        }
    }
}
