import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query(sort: \HearingTest.date, order: .reverse) private var tests: [HearingTest]
    @AppStorage("isPro") private var isPro = false
    @State private var showPaywall = false

    /// Free users see only the most recent test in the list; trend is Pro-only.
    private var visibleTests: [HearingTest] {
        isPro ? tests : Array(tests.prefix(1))
    }

    var body: some View {
        NavigationStack {
            Group {
                if tests.isEmpty {
                    ScrollView {
                        EmptyStateView(
                            icon: "clock.arrow.circlepath",
                            title: "No history yet",
                            message: "Once you run a screening, your past results and trend will live here."
                        )
                        .padding(.top, 60)
                    }
                } else {
                    content
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("History")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 18) {
                if isPro {
                    trendCard
                } else {
                    trendLockedCard
                }

                VStack(spacing: 12) {
                    ForEach(visibleTests) { test in
                        NavigationLink {
                            ResultsView(test: test)
                        } label: {
                            historyRow(test)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !isPro && tests.count > 1 {
                    lockedHistoryCard
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 28)
        }
    }

    private var trendCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "PTA trend")
                PTATrendChart(tests: tests)
                AudiogramLegend()
                ForEach(Ear.allCases) { ear in
                    Text(AnalysisEngine.trendSummary(for: ear, in: tests))
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var trendLockedCard: some View {
        Button { showPaywall = true } label: {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        SectionLabel(text: "PTA trend")
                        Spacer()
                        Image(systemName: "lock.fill").foregroundStyle(Theme.accent)
                    }
                    Text("Track how your hearing changes over time with Hark Pro. Free includes your latest result.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Unlock trends →")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the Hark Pro upgrade screen.")
    }

    private var lockedHistoryCard: some View {
        Button { showPaywall = true } label: {
            Card {
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill").foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    Text("\(tests.count - 1) more past test\(tests.count - 1 == 1 ? "" : "s") in Hark Pro")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func historyRow(_ test: HearingTest) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(test.date, format: .dateTime.month().day().year())
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
                HStack(spacing: 18) {
                    ptaPill(label: "R", value: test.ptaRight, color: Theme.earRight)
                    ptaPill(label: "L", value: test.ptaLeft, color: Theme.earLeft)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowA11y(test))
    }

    private func ptaPill(label: String, value: Double?, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(Theme.rounded(13, .bold))
                .foregroundStyle(color)
            Text(value.map { "PTA \(Int($0.rounded())) dB" } ?? "—")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(color.opacity(0.14)))
    }

    private func rowA11y(_ test: HearingTest) -> String {
        let d = test.date.formatted(date: .abbreviated, time: .omitted)
        let r = test.ptaRight.map { "right \(Int($0.rounded())) decibels" } ?? "right not measured"
        let l = test.ptaLeft.map { "left \(Int($0.rounded())) decibels" } ?? "left not measured"
        return "Test from \(d), \(r), \(l)."
    }
}

/// PTA-over-time trend, per ear.
private struct PTATrendChart: View {
    let tests: [HearingTest]

    private var points: [TrendPoint] { AnalysisEngine.trend(from: tests) }

    var body: some View {
        Chart(points) { p in
            LineMark(
                x: .value("Date", p.date),
                y: .value("PTA", p.pta),
                series: .value("Ear", p.ear.rawValue)
            )
            .foregroundStyle(p.ear == .right ? Theme.earRight : Theme.earLeft)
            .lineStyle(StrokeStyle(lineWidth: 2.5))

            PointMark(
                x: .value("Date", p.date),
                y: .value("PTA", p.pta)
            )
            .foregroundStyle(p.ear == .right ? Theme.earRight : Theme.earLeft)
            .symbol(p.ear == .right ? .circle : .square)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v))")
                            .font(Theme.rounded(10))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisValueLabel(format: .dateTime.month(.abbreviated))
                    .font(Theme.rounded(10))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(height: 200)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pure tone average trend over time")
        .accessibilityValue(trendA11y)
    }

    private var trendA11y: String {
        func describe(_ ear: Ear) -> String {
            let pts = points.filter { $0.ear == ear }
            guard !pts.isEmpty else { return "" }
            let vals = pts.map { "\(Int($0.pta.rounded()))" }.joined(separator: ", ")
            return "\(ear.rawValue) ear PTA over time: \(vals) decibels."
        }
        let r = describe(.right)
        let l = describe(.left)
        let combined = [r, l].filter { !$0.isEmpty }.joined(separator: " ")
        return combined.isEmpty ? "No trend data yet." : combined
    }
}
