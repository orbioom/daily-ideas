import SwiftUI
import SwiftData
import Charts

struct ProjectionView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("retirementAge") private var retirementAge = 65.0
    @Query private var profiles: [Profile]

    private var profile: Profile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile {
                    VStack(spacing: 16) {
                        chartCard(profile)
                        explainerCard(profile)
                        tableCard(profile)
                    }
                    .padding()
                } else {
                    EmptyStateView(icon: "chart.xyaxis.line",
                                   title: "No plan yet",
                                   message: "Set up your assumptions on the Plan tab to see your projection.")
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Projection")
        }
    }

    private func chartCard(_ profile: Profile) -> some View {
        let points = FIEngine.projection(profile: profile)
        let fiNumber = profile.fiNumber
        return VStack(alignment: .leading, spacing: 10) {
            Text("Portfolio over time").font(.headline)
            Chart {
                ForEach(points) { point in
                    AreaMark(x: .value("Age", point.age),
                             y: .value("Value", point.withContributions))
                    .foregroundStyle(LinearGradient(colors: [Theme.teal.opacity(0.35), Theme.teal.opacity(0.04)],
                                                    startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Age", point.age),
                             y: .value("Value", point.withContributions),
                             series: .value("Path", "Contributing"))
                    .foregroundStyle(Theme.teal)
                    .interpolationMethod(.monotone)
                }
                ForEach(points) { point in
                    LineMark(x: .value("Age", point.age),
                             y: .value("Value", point.coastOnly),
                             series: .value("Path", "Coasting"))
                    .foregroundStyle(Theme.sun)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    .interpolationMethod(.monotone)
                }
                RuleMark(y: .value("FI", fiNumber))
                    .foregroundStyle(Theme.coral)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("FI: \(FIEngine.money(fiNumber, code: profile.currencyCode, compact: true))")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Theme.coral)
                    }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(FIEngine.money(v, code: profile.currencyCode, compact: true))
                        }
                    }
                }
            }
            .chartXAxisLabel("Age")
            .frame(height: 240)
            .accessibilityLabel("Projected portfolio value by age, showing a contributing path and a coast-only path against your FI line")

            HStack(spacing: 16) {
                legend(color: Theme.teal, label: "Keep contributing")
                legend(color: Theme.sun, label: "Coast (stop now)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .coastCard()
    }

    private func legend(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 16, height: 4)
            Text(label).font(.caption).foregroundStyle(Theme.inkSoft(scheme))
        }
    }

    private func explainerCard(_ profile: Profile) -> some View {
        let years = FIEngine.yearsToFI(profile: profile)
        return VStack(alignment: .leading, spacing: 8) {
            Text("What this shows").font(.headline)
            if let years {
                Text("On your current plan you reach financial independence in \(FIEngine.yearsLabel(years)), at age \(String(format: "%.0f", profile.currentAge + years)). The gold dashed line is what happens if you stopped adding money today — watch how compound growth keeps climbing on its own.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft(scheme))
            } else {
                Text("With these assumptions, FI isn't reachable within the chart. Try raising your contribution or savings rate, or revisiting your target spending.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft(scheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .coastCard()
    }

    private func tableCard(_ profile: Profile) -> some View {
        let points = FIEngine.projection(profile: profile)
        let milestones = stride(from: 0, to: points.count, by: max(points.count / 8, 1)).map { points[$0] }
        return VStack(alignment: .leading, spacing: 10) {
            Text("Year by year").font(.headline)
            ForEach(milestones) { point in
                HStack {
                    Text("Age \(String(format: "%.0f", point.age))")
                        .font(.subheadline)
                        .frame(width: 70, alignment: .leading)
                    Spacer()
                    Text(FIEngine.money(point.withContributions, code: profile.currencyCode, compact: true))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(point.withContributions >= profile.fiNumber ? Theme.teal : Theme.ink(scheme))
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Age \(String(format: "%.0f", point.age)): \(FIEngine.money(point.withContributions, code: profile.currencyCode))")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .coastCard()
    }
}
