import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var watches: [Watch]

    private var rated: [Watch] { watches.filter { $0.dailyRate != nil } }

    private var mostAccurate: Watch? {
        rated.min { abs($0.dailyRate ?? .infinity) < abs($1.dailyRate ?? .infinity) }
    }
    private var averageAbsRate: Double? {
        guard !rated.isEmpty else { return nil }
        return rated.map { abs($0.dailyRate ?? 0) }.reduce(0, +) / Double(rated.count)
    }

    private struct GradeCount: Identifiable {
        let grade: AccuracyGrade; let count: Int
        var id: String { grade.rawValue }
    }
    private var gradeCounts: [GradeCount] {
        let order: [AccuracyGrade] = [.chronometer, .excellent, .good, .fair, .needsRegulation]
        return order.map { g in
            GradeCount(grade: g, count: watches.filter { $0.grade == g }.count)
        }.filter { $0.count > 0 }
    }

    private var positionSensitive: [(Watch, Double)] {
        watches.compactMap { w in
            RateEngine.positionalDelta(w.measurements).map { (w, $0) }
        }
        .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    if watches.isEmpty {
                        EmptyStateView(icon: "chart.xyaxis.line",
                                       title: "No insights yet",
                                       message: "Add watches and log readings to compare accuracy across your whole collection.")
                            .padding(.top, 50)
                    } else {
                        VStack(spacing: 18) {
                            statGrid
                            if !gradeCounts.isEmpty { gradeCard }
                            if !positionSensitive.isEmpty { positionCard }
                        }
                        .padding(.horizontal, 18).padding(.vertical, 14)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var statGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatTile(value: "\(watches.count)", label: "Watches")
                StatTile(value: averageAbsRate.map { String(format: "%.1f", $0) } ?? "—",
                         label: "Avg |rate|", accent: Brand.info)
            }
            if let best = mostAccurate {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "Most accurate")
                    HStack {
                        Circle().fill(Color(hex: best.accentHex)).frame(width: 12, height: 12)
                        Text(best.displayName).font(.headline).foregroundStyle(Brand.text)
                        Spacer()
                        RateBadge(rate: best.dailyRate, grade: best.grade, compact: true)
                    }
                }
                .glassCard()
            }
        }
    }

    private var gradeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Grade spread")
            Chart(gradeCounts) { gc in
                BarMark(x: .value("Grade", gc.grade.rawValue),
                        y: .value("Count", gc.count))
                .foregroundStyle(gc.grade.tint)
                .cornerRadius(4)
            }
            .chartYAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
            .frame(height: 170)
            .accessibilityLabel("Number of watches in each accuracy grade")
        }
        .glassCard()
    }

    private var positionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Most position-sensitive", trailing: "spread s/d")
            ForEach(positionSensitive.prefix(5), id: \.0.persistentModelID) { w, delta in
                HStack {
                    Circle().fill(Color(hex: w.accentHex)).frame(width: 10, height: 10)
                    Text(w.displayName).font(.subheadline).foregroundStyle(Brand.text)
                    Spacer()
                    Text(String(format: "%.1f", delta))
                        .font(Brand.mono(14, weight: .medium)).foregroundStyle(Brand.warn)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(w.displayName): positional spread \(String(format: "%.1f", delta)) seconds per day")
            }
        }
        .glassCard()
    }
}
