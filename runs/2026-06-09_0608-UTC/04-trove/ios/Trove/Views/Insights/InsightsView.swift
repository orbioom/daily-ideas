import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \Person.sortIndex) private var people: [Person]
    @Query(sort: \Occasion.sortIndex) private var occasions: [Occasion]
    @Query private var gifts: [Gift]

    @AppStorage("trove.currencyCode") private var currencyCode = "USD"

    private var spent: Double { GiftEngine.totalSpend(gifts) }
    private var budget: Double { GiftEngine.totalBudget(occasions) }
    private var budgetFraction: Double { budget > 0 ? min(spent / budget, 1) : 0 }
    private var tally: [GiftStatus: Int] { GiftEngine.statusTally(gifts) }
    private var byPerson: [GiftEngine.NamedSpend] { GiftEngine.spendByPerson(people) }
    private var byOccasion: [GiftEngine.NamedSpend] { GiftEngine.spendByOccasion(occasions) }
    private var toBuy: [Gift] {
        gifts.filter { !$0.isAcquired }.sorted { $0.createdAt > $1.createdAt }
    }

    private var statusData: [(status: GiftStatus, count: Int)] {
        GiftStatus.allCases.compactMap { s in
            let c = tally[s] ?? 0
            return c > 0 ? (s, c) : nil
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if gifts.isEmpty {
                    EmptyStateView(
                        icon: "chart.pie",
                        title: "Nothing to chart yet",
                        message: "Add gifts and budgets and your spend, status mix, and to-buy list will show up here.")
                    .glassCard()
                } else {
                    totalsCard
                    statusDonut
                    spendByPersonChart
                    spendByOccasionChart
                    toBuySection
                }
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Insights")
    }

    private var totalsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Total spend")
            HStack(spacing: 16) {
                ProgressRing(progress: budgetFraction, lineWidth: 12,
                             tint: spent > budget && budget > 0 ? Brand.danger : Brand.live)
                    .frame(width: 72, height: 72)
                    .overlay {
                        Text(budget > 0 ? "\(Int((budgetFraction * 100).rounded()))%" : "—")
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(Brand.text)
                    }
                VStack(alignment: .leading, spacing: 4) {
                    Text(Format.currency(spent, code: currencyCode))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Brand.text)
                    Text(budget > 0
                         ? "of \(Format.currency(budget, code: currencyCode)) budgeted"
                         : "across all occasions")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                }
                Spacer()
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total spend \(Format.currency(spent, code: currencyCode))"
            + (budget > 0 ? " of \(Format.currency(budget, code: currencyCode)) budget" : ""))
    }

    private var statusDonut: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Gift status")
            if statusData.isEmpty {
                emptyChartNote("No gifts to break down yet.")
            } else {
                Chart(statusData, id: \.status) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(item.status.color)
                }
                .chartLegend(.hidden)
                .frame(height: 180)
                .accessibilityHidden(true)
                legend
            }
        }
        .glassCard()
    }

    private var legend: some View {
        VStack(spacing: 8) {
            ForEach(statusData, id: \.status) { item in
                HStack(spacing: 8) {
                    StatusDot(color: item.status.color)
                    Text(item.status.label)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text)
                    Spacer()
                    Text("\(item.count)")
                        .font(Brand.mono(13, weight: .medium))
                        .foregroundStyle(Brand.text2)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(item.status.label): \(item.count)")
            }
        }
    }

    private var spendByPersonChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Spend by person")
            if byPerson.isEmpty {
                emptyChartNote("No acquired gifts to total yet.")
            } else {
                Chart(byPerson) { item in
                    BarMark(
                        x: .value("Amount", item.amount),
                        y: .value("Person", item.name)
                    )
                    .foregroundStyle(Brand.info)
                    .cornerRadius(5)
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(Format.currency(amount, code: currencyCode))
                            }
                        }
                    }
                }
                .frame(height: CGFloat(byPerson.count) * 40 + 30)
                .accessibilityHidden(true)
            }
        }
        .glassCard()
    }

    private var spendByOccasionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Spend by occasion")
            if byOccasion.isEmpty {
                emptyChartNote("No acquired gifts to total yet.")
            } else {
                Chart(byOccasion) { item in
                    BarMark(
                        x: .value("Amount", item.amount),
                        y: .value("Occasion", item.name)
                    )
                    .foregroundStyle(Brand.magic)
                    .cornerRadius(5)
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(Format.currency(amount, code: currencyCode))
                            }
                        }
                    }
                }
                .frame(height: CGFloat(byOccasion.count) * 40 + 30)
                .accessibilityHidden(true)
            }
        }
        .glassCard()
    }

    private var toBuySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "To buy (\(toBuy.count))")
            if toBuy.isEmpty {
                Text("All caught up — no outstanding ideas.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            } else {
                VStack(spacing: 10) {
                    ForEach(toBuy.prefix(12)) { gift in
                        GiftRow(gift: gift, showPerson: true, showOccasion: true, currencyCode: currencyCode)
                    }
                }
            }
        }
        .glassCard(padding: 14)
    }

    private func emptyChartNote(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Brand.text2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
