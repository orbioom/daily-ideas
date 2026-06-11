import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.colorScheme) private var scheme
    @Query private var applications: [Application]

    private var sent: [Application] {
        applications.filter { $0.appliedDate != nil }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sent.count < 2 {
                    EmptyStateView(icon: "chart.bar",
                                   title: "Insights need a few applications",
                                   message: "Log at least two sent applications and Hired will chart your funnel, response rate, and weekly pace.")
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            statRow
                            funnelCard
                            weeklyCard
                            excitementCard
                        }
                        .padding()
                    }
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Insights")
        }
    }

    private var statRow: some View {
        let rate = FunnelEngine.responseRate(applications: applications)
        let median = FunnelEngine.medianDaysToFirstResponse(applications: applications)
        return HStack(spacing: 12) {
            statTile(title: "Sent", value: "\(sent.count)")
            statTile(title: "Response rate",
                     value: rate.map { "\(Int(($0 * 100).rounded()))%" } ?? "—",
                     caption: "any reply counts")
            statTile(title: "First reply",
                     value: median.map { "\($0)d" } ?? "—",
                     caption: "median wait")
        }
    }

    private func statTile(title: String, value: String, caption: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.inkSoft(scheme))
            Text(value)
                .font(Theme.display(22))
                .foregroundStyle(Theme.ink(scheme))
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(Theme.inkSoft(scheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .hiredCard()
        .accessibilityElement(children: .combine)
    }

    private var funnelCard: some View {
        let steps = FunnelEngine.funnel(applications: applications)
        let maxCount = max(steps.map(\.count).max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Your funnel").font(.headline)
            ForEach(steps) { step in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(step.label)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(step.count)")
                            .font(.subheadline)
                            .monospacedDigit()
                        if step.id > 0 {
                            Text("(\(Int((step.conversion * 100).rounded()))%)")
                                .font(.caption)
                                .foregroundStyle(Theme.inkSoft(scheme))
                        }
                    }
                    GeometryReader { geo in
                        Capsule()
                            .fill(Theme.blue.opacity(0.85 - Double(step.id) * 0.15))
                            .frame(width: max(geo.size.width * CGFloat(step.count) / CGFloat(maxCount), 6))
                    }
                    .frame(height: 12)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(step.label): \(step.count) applications\(step.id > 0 ? ", \(Int((step.conversion * 100).rounded())) percent conversion from previous step" : "")")
            }
            Text("Fix the step with the steepest drop — that's where your search is leaking.")
                .font(.caption)
                .foregroundStyle(Theme.inkSoft(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .hiredCard()
    }

    private var weeklyCard: some View {
        let weekly = FunnelEngine.weeklyApplied(applications: applications)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Applications per week").font(.headline)
            Chart(weekly, id: \.weekStart) { item in
                BarMark(x: .value("Week", item.weekStart, unit: .weekOfYear),
                        y: .value("Sent", item.count))
                .foregroundStyle(Theme.blue)
                .cornerRadius(3)
            }
            .frame(height: 150)
            .accessibilityLabel("Bar chart of applications sent per week over the last 8 weeks")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .hiredCard()
    }

    private var excitementCard: some View {
        let counts = Dictionary(grouping: applications, by: \.excitement)
            .mapValues(\.count)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Excitement spread").font(.headline)
            Chart((1...5).map { (level: $0, count: counts[$0] ?? 0) }, id: \.level) { item in
                BarMark(x: .value("Excitement", "\(item.level)"),
                        y: .value("Count", item.count))
                .foregroundStyle(item.level >= 4 ? Color.orange : Theme.inkSoft(scheme).opacity(0.5))
                .cornerRadius(3)
            }
            .frame(height: 130)
            .accessibilityLabel("How excited you are across your applications, 1 to 5")
            Text("If most of your pipeline is a 2, the problem isn't interviews — it's targeting.")
                .font(.caption)
                .foregroundStyle(Theme.inkSoft(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .hiredCard()
    }
}
