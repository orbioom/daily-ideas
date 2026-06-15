import SwiftUI
import SwiftData
import Charts

/// Progress over time: WPM trend, accuracy trend, headline bests/totals, and a teaser into the
/// full key heatmap (on the Keys tab). Full charts gate behind Pro.
struct StatsView: View {
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \TestResult.date, order: .forward) private var results: [TestResult]

    @State private var paywallReason: PaywallReason?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if results.isEmpty {
                        EmptyStateView(
                            symbol: "chart.line.uptrend.xyaxis",
                            title: "No stats yet",
                            message: "Finish a lesson or a test and your progress will chart here."
                        )
                        .padding(.top, 40)
                    } else {
                        summaryGrid
                        if isPro {
                            wpmChartCard
                            accuracyChartCard
                        } else {
                            lockedChartsCard
                        }
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Stats")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    // MARK: Aggregates (guarded against empty / zero)

    private var bestWPM: Double { results.map(\.wpm).max() ?? 0 }
    private var avgAccuracy: Double {
        guard !results.isEmpty else { return 0 }
        return results.map(\.accuracy).reduce(0, +) / Double(results.count)
    }
    private var totalChars: Int { results.map(\.charCount).reduce(0, +) }
    private var totalWords: Int { totalChars / 5 }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryTile(value: "\(Int(bestWPM.rounded()))", label: "Best WPM",
                        symbol: "bolt.fill", tint: Theme.accentDeep)
            summaryTile(value: "\(Int((avgAccuracy * 100).rounded()))%", label: "Avg accuracy",
                        symbol: "scope", tint: Theme.good)
            summaryTile(value: totalWords.formatted(), label: "Words typed",
                        symbol: "text.word.spacing", tint: Theme.ink)
            summaryTile(value: "\(results.count)", label: "Sessions",
                        symbol: "checkmark.circle.fill", tint: Theme.ink)
        }
    }

    private func summaryTile(value: String, label: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.mono(26, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
            Text(label)
                .font(Theme.rounded(12, .semibold))
                .foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: Charts

    private var wpmChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "WPM over time", systemImage: "bolt.fill")
            Chart(results) { r in
                LineMark(
                    x: .value("Date", r.date),
                    y: .value("WPM", r.wpm)
                )
                .foregroundStyle(Theme.accent)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", r.date),
                    y: .value("WPM", r.wpm)
                )
                .foregroundStyle(Theme.accentDeep)
                .symbolSize(18)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 200)
            .accessibilityLabel("WPM trend chart")
            .accessibilityValue("Best \(Int(bestWPM.rounded())) words per minute")
        }
        .padding(18)
        .cardSurface()
    }

    private var accuracyChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Accuracy over time", systemImage: "scope")
            Chart(results) { r in
                LineMark(
                    x: .value("Date", r.date),
                    y: .value("Accuracy", r.accuracy * 100)
                )
                .foregroundStyle(Theme.good)
                .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: 50...100)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 180)
            .accessibilityLabel("Accuracy trend chart")
            .accessibilityValue("Average \(Int((avgAccuracy * 100).rounded())) percent")
        }
        .padding(18)
        .cardSurface()
    }

    private var lockedChartsCard: some View {
        Button {
            paywallReason = .fullStats
        } label: {
            VStack(spacing: 14) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Unlock your full trends")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Go Pro to chart your WPM and accuracy across every session and watch the line climb.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                ProLockChip()
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .cardSurface()
        }
        .buttonStyle(PressableScale())
    }
}
