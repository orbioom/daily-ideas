import SwiftUI
import SwiftData
import Charts

struct ForecastView: View {
    @AppStorage("currentBalance") private var currentBalance = 0.0
    @AppStorage("balanceAsOf") private var balanceAsOf = 0.0
    @AppStorage("buffer") private var buffer = 100.0
    @AppStorage("currencyCode") private var currencyCode = "USD"

    @Query private var recurring: [RecurringItem]
    @Query private var oneOffs: [OneOffItem]
    @State private var showBalanceEdit = false

    private var forecast: Forecast {
        ForecastContext.current(recurring: recurring, oneOffs: oneOffs)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    safeToSpendCard
                    balanceRow
                    if forecast.lowestBalance < buffer { warningCard }
                    nextPaydayCard
                    chartCard
                }
                .padding(.horizontal, 16).padding(.bottom, 24)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Runway")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showBalanceEdit = true } label: { Image(systemName: "pencil.circle") }
                        .accessibilityLabel("Update balance")
                }
            }
            .sheet(isPresented: $showBalanceEdit) {
                BalanceEditSheet(balance: $currentBalance, asOf: $balanceAsOf, currency: currencyCode)
            }
        }
    }

    private var safeToSpendCard: some View {
        let f = forecast
        return Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("SAFE TO SPEND").font(.system(size: 13, weight: .bold)).tracking(1)
                    .foregroundStyle(Theme.accent)
                Text(Money.string(f.safeToSpend, code: currencyCode))
                    .font(Theme.num(46)).foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.6).lineLimit(1)
                if let payday = f.nextIncomeDate {
                    Text("Before your next income on \(payday.formatted(.dateTime.weekday(.wide).month().day())).")
                        .font(.system(size: 14)).foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Over the next \(Horizon.days) days, keeping a \(Money.string(buffer, code: currencyCode)) buffer.")
                        .font(.system(size: 14)).foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Safe to spend \(Money.string(f.safeToSpend, code: currencyCode))")
    }

    private var balanceRow: some View {
        Button { showBalanceEdit = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current balance").font(.system(size: 13)).foregroundStyle(Theme.inkSoft)
                    Text(Money.string(currentBalance, code: currencyCode))
                        .font(Theme.num(24)).foregroundStyle(Theme.ink)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("As of").font(.system(size: 13)).foregroundStyle(Theme.inkSoft)
                    Text(Date(timeIntervalSince1970: balanceAsOf), format: .dateTime.month().day())
                        .font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.inkSoft)
                }
                Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(Theme.inkFaint)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface))
        }
        .buttonStyle(.plain)
    }

    private var warningCard: some View {
        let f = forecast
        return HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 22)).foregroundStyle(f.lowestBalance < 0 ? Theme.danger : Theme.caution)
            VStack(alignment: .leading, spacing: 2) {
                Text(f.lowestBalance < 0 ? "Projected shortfall" : "Balance runs low")
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                if let d = f.lowestDate {
                    Text("Dips to \(Money.string(f.lowestBalance, code: currencyCode)) on \(d.formatted(.dateTime.month().day())).")
                        .font(.system(size: 13)).foregroundStyle(Theme.inkSoft)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16)
            .fill((f.lowestBalance < 0 ? Theme.danger : Theme.caution).opacity(0.14)))
    }

    private var nextPaydayCard: some View {
        let f = forecast
        return Card {
            HStack {
                CategoryBadge(category: "Paycheck", kind: .income, size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next income").font(.system(size: 13)).foregroundStyle(Theme.inkSoft)
                    if let d = f.nextIncomeDate {
                        Text(d, format: .dateTime.weekday(.wide).month().day())
                            .font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.ink)
                    } else {
                        Text("None in \(Horizon.days) days").font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                    }
                }
                Spacer()
                if f.nextIncomeAmount > 0 {
                    Text(Money.string(f.nextIncomeAmount, code: currencyCode, showSign: true))
                        .font(Theme.num(20)).foregroundStyle(Theme.accent)
                }
            }
        }
    }

    private var chartCard: some View {
        let pts = Array(forecast.projections.prefix(28))
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Next 4 weeks").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.ink)
                Chart {
                    ForEach(pts) { p in
                        AreaMark(x: .value("Date", p.date),
                                 y: .value("Balance", max(p.endBalance, 0)))
                            .foregroundStyle(LinearGradient(colors: [Theme.accent.opacity(0.30), Theme.accent.opacity(0.02)],
                                                            startPoint: .top, endPoint: .bottom))
                        LineMark(x: .value("Date", p.date),
                                 y: .value("Balance", p.endBalance))
                            .foregroundStyle(Theme.accent)
                            .interpolationMethod(.monotone)
                    }
                    RuleMark(y: .value("Buffer", buffer))
                        .foregroundStyle(Theme.caution.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    RuleMark(y: .value("Zero", 0)).foregroundStyle(Theme.danger.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) {
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: 180)
            }
        }
    }
}

struct BalanceEditSheet: View {
    @Binding var balance: Double
    @Binding var asOf: Double
    let currency: String
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Current balance") {
                    HStack {
                        Text(symbol).foregroundStyle(Theme.inkSoft)
                        TextField("0.00", text: $text).keyboardType(.decimalPad)
                            .font(.system(size: 17, design: .rounded))
                    }
                }
                Section("As of") {
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                }
                Section {
                    Text("Update this whenever you check your bank, so the forecast stays accurate.")
                        .font(.system(size: 13)).foregroundStyle(Theme.inkSoft)
                }
            }
            .navigationTitle("Update balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        balance = Double(text.replacingOccurrences(of: ",", with: ".")) ?? balance
                        asOf = date.timeIntervalSince1970
                        Haptics.success(); dismiss()
                    }
                }
            }
            .onAppear {
                text = String(format: "%.2f", balance)
                date = Date(timeIntervalSince1970: asOf)
            }
        }
    }

    private var symbol: String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = currency
        return f.currencySymbol ?? "$"
    }
}
