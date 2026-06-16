import SwiftUI
import Charts

struct MilesByMonthChart: View {
    @EnvironmentObject private var settings: AppSettings
    let data: [MonthlyMiles]

    private var hasMiles: Bool { data.contains { $0.total > 0 } }

    var body: some View {
        Card {
            if !hasMiles {
                miniEmpty("No miles logged this year.")
            } else {
                Chart {
                    ForEach(data) { m in
                        BarMark(
                            x: .value("Month", m.label),
                            y: .value("Miles", settings.distanceValue(m.businessMiles))
                        )
                        .foregroundStyle(by: .value("Type", "Business"))

                        BarMark(
                            x: .value("Month", m.label),
                            y: .value("Miles", settings.distanceValue(m.otherMiles))
                        )
                        .foregroundStyle(by: .value("Type", "Other"))
                    }
                }
                .chartForegroundStyleScale(
                    domain: ["Business", "Other"],
                    range: [Theme.palette[0], Theme.inkSoft.opacity(0.55)]
                )
                .chartLegend(position: .bottom, spacing: 8)
                .frame(height: 200)
                .chartYAxisLabel(settings.distanceUnit.shortLabel)
                .accessibilityLabel("Miles by month")
                .accessibilityValue(monthSummary)
            }
        }
    }

    private var monthSummary: String {
        let top = data.max { $0.total < $1.total }
        guard let top, top.total > 0 else { return "No miles" }
        return "Busiest month \(top.label) with \(settings.distance(top.total))"
    }

    private func miniEmpty(_ text: String) -> some View {
        HStack {
            Image(systemName: "chart.bar.xaxis").foregroundStyle(Theme.inkSoft)
            Text(text).font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .accessibilityElement(children: .combine)
    }
}

struct DeductionDonutChart: View {
    @EnvironmentObject private var settings: AppSettings
    let result: DeductionResult

    private struct Slice: Identifiable {
        let id = UUID()
        let label: String
        let amount: Decimal
        let color: Color
    }

    private var slices: [Slice] {
        var out: [Slice] = []
        for purpose in TripPurpose.allCases where purpose.isDeductible {
            let amount = result.mileageDeductionByPurpose[purpose] ?? 0
            if amount > 0 {
                out.append(Slice(label: "\(purpose.rawValue) miles", amount: amount, color: purpose.tint))
            }
        }
        for (cat, amount) in result.deductibleExpensesByCategory.sorted(by: { $0.value > $1.value }) where amount > 0 {
            out.append(Slice(label: cat.rawValue, amount: amount, color: cat.tint))
        }
        return out
    }

    var body: some View {
        Card {
            if slices.isEmpty {
                emptyMini
            } else {
                VStack(spacing: 14) {
                    Chart(slices) { slice in
                        SectorMark(
                            angle: .value("Amount", NSDecimalNumber(decimal: slice.amount).doubleValue),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(slice.color)
                        .cornerRadius(3)
                    }
                    .frame(height: 190)
                    .chartLegend(.hidden)
                    .overlay {
                        VStack(spacing: 2) {
                            Text("Total")
                                .font(Theme.rounded(12, .medium))
                                .foregroundStyle(Theme.inkSoft)
                            Text(settings.moneyCompact(result.totalDeduction))
                                .font(Theme.mono(18, .bold))
                                .foregroundStyle(Theme.ink)
                        }
                    }
                    legend
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Deduction by category, total \(settings.money(result.totalDeduction))")
            }
        }
    }

    private var legend: some View {
        VStack(spacing: 6) {
            ForEach(slices) { slice in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3).fill(slice.color).frame(width: 12, height: 12)
                    Text(slice.label)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(settings.money(slice.amount))
                        .font(Theme.mono(13, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
    }

    private var emptyMini: some View {
        HStack {
            Image(systemName: "chart.pie").foregroundStyle(Theme.inkSoft)
            Text("No deductible amounts yet.").font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .accessibilityElement(children: .combine)
    }
}

struct BusinessSplitChart: View {
    @EnvironmentObject private var settings: AppSettings
    let result: DeductionResult

    private struct Slice: Identifiable {
        let id = UUID()
        let label: String
        let miles: Double
        let color: Color
    }

    private var slices: [Slice] {
        let business = result.businessMiles
        let other = max(0, result.totalMiles - business)
        var out: [Slice] = []
        if business > 0 { out.append(Slice(label: "Business", miles: business, color: Theme.palette[0])) }
        if other > 0 { out.append(Slice(label: "Personal & other", miles: other, color: Theme.inkSoft.opacity(0.6))) }
        return out
    }

    var body: some View {
        Card {
            if slices.isEmpty {
                HStack {
                    Image(systemName: "chart.pie").foregroundStyle(Theme.inkSoft)
                    Text("No miles logged yet.").font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .accessibilityElement(children: .combine)
            } else {
                HStack(spacing: 18) {
                    Chart(slices) { slice in
                        SectorMark(
                            angle: .value("Miles", slice.miles),
                            innerRadius: .ratio(0.62),
                            angularInset: 1.5
                        )
                        .foregroundStyle(slice.color)
                        .cornerRadius(3)
                    }
                    .frame(width: 130, height: 130)
                    .chartLegend(.hidden)
                    .overlay {
                        Text(NumberFormatting.percent(result.businessUsePercent))
                            .font(Theme.mono(20, .bold))
                            .foregroundStyle(Theme.accent)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(slices) { slice in
                            HStack(spacing: 8) {
                                Circle().fill(slice.color).frame(width: 11, height: 11)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(slice.label)
                                        .font(Theme.rounded(14, .semibold))
                                        .foregroundStyle(Theme.ink)
                                    Text(settings.distance(slice.miles))
                                        .font(Theme.mono(12))
                                        .foregroundStyle(Theme.inkSoft)
                                }
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Business use \(NumberFormatting.percent(result.businessUsePercent)). Business \(settings.distance(result.businessMiles)) of \(settings.distance(result.totalMiles)) total.")
            }
        }
    }
}
