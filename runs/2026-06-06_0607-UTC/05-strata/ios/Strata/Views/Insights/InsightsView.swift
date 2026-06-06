import SwiftUI
import SwiftData
import Charts

/// The Insights tab: send pyramid, flash/onsight rate, max grades, and monthly
/// progression — all computed from real attempts via the pure Analytics engine.
struct InsightsView: View {
    @Environment(SettingsStore.self) private var settings
    @Query private var sessions: [Session]
    @Query private var climbs: [Climb]

    @State private var family: GradeFamily = .boulder

    private var attempts: [Attempt] { sessions.flatMap(\.attempts) }
    private var system: GradeSystem { settings.system(for: family) }

    private var summary: Analytics.Summary {
        Analytics.summary(sessions: sessions, climbs: climbs)
    }
    private var pyramid: [Analytics.PyramidRung] {
        Analytics.sendPyramid(attempts: attempts, family: family)
    }
    private var progression: [Analytics.MonthPoint] {
        Analytics.monthlyProgression(sessions: sessions, family: family)
    }

    private var hasData: Bool { !attempts.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                if !hasData {
                    EmptyStateView(
                        icon: "chart.bar.xaxis",
                        title: "No data yet",
                        message: "Log a few sessions with attempts and your send pyramid, flash rate, and progression will appear here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            overviewCard
                            familyPicker
                            ratesCard
                            pyramidCard
                            progressionCard
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    // MARK: - Overview

    private var overviewCard: some View {
        GlassCard {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    StatTile(value: "\(summary.sessionCount)", caption: "Sessions")
                    Divider().frame(height: 34)
                    StatTile(value: "\(summary.sendCount)", caption: "Sends", tint: Brand.send)
                    Divider().frame(height: 34)
                    StatTile(value: "\(summary.projectsInProgress)", caption: "Projects", tint: Brand.project)
                }
                Divider()
                HStack(spacing: 12) {
                    StatTile(value: "\(summary.attemptCount)", caption: "Attempts")
                    Divider().frame(height: 34)
                    StatTile(value: hoursLabel, caption: "Total time")
                }
            }
        }
    }

    private var hoursLabel: String {
        let h = summary.totalMinutes / 60
        let m = summary.totalMinutes % 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    private var familyPicker: some View {
        Picker("Family", selection: $family) {
            Text("Boulders").tag(GradeFamily.boulder)
            Text("Routes").tag(GradeFamily.route)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Rates

    private var ratesCard: some View {
        let familyAttempts = attempts.filter { $0.gradeFamily == family }
        let flash = Analytics.flashRate(attempts: familyAttempts)
        let maxSend = Analytics.maxSendIndex(attempts: familyAttempts, family: family)
        let maxAttempted = Analytics.maxAttemptedIndex(attempts: familyAttempts, family: family)

        return GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(text: "\(family == .boulder ? "Boulder" : "Route") summary")
                HStack(spacing: 12) {
                    StatTile(value: flash.map { "\(Int(($0 * 100).rounded()))%" } ?? "—",
                             caption: "Flash / onsight")
                    Divider().frame(height: 34)
                    StatTile(value: maxSend.flatMap { GradeScale.display(index: $0, in: system) } ?? "—",
                             caption: "Max send", tint: Brand.send)
                    Divider().frame(height: 34)
                    StatTile(value: maxAttempted.flatMap { GradeScale.display(index: $0, in: system) } ?? "—",
                             caption: "Max tried")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Pyramid

    private var pyramidCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Send pyramid")
                if pyramid.isEmpty {
                    Text("No \(family == .boulder ? "boulder" : "route") sends yet.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                } else {
                    let maxCount = pyramid.map(\.count).max() ?? 1
                    VStack(spacing: 8) {
                        ForEach(pyramid) { rung in
                            pyramidRow(rung, maxCount: maxCount)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func pyramidRow(_ rung: Analytics.PyramidRung, maxCount: Int) -> some View {
        let label = GradeScale.display(index: rung.index, in: system) ?? "—"
        let fraction = maxCount > 0 ? CGFloat(rung.count) / CGFloat(maxCount) : 0
        return HStack(spacing: 10) {
            Text(label)
                .font(Brand.mono(14, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Brand.text)
                .frame(width: 52, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Brand.glassStroke.opacity(0.22))
                    Capsule()
                        .fill(Brand.send.opacity(0.85))
                        .frame(width: max(geo.size.width * fraction, 6))
                }
            }
            .frame(height: 18)
            Text("\(rung.count)")
                .font(Brand.mono(14, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Brand.text2)
                .frame(width: 24, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(rung.count) send\(rung.count == 1 ? "" : "s")")
    }

    // MARK: - Progression

    private var progressionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Hardest send by month")
                let points = progression.filter { $0.hardestIndex != nil }
                if points.count < 1 {
                    Text("Log sends across a couple of months to see your progression curve.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                } else {
                    progressionChart(points)
                        .frame(height: 180)
                        .accessibilityLabel(progressionAccessibility(points))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func progressionChart(_ points: [Analytics.MonthPoint]) -> some View {
        let maxIndex = points.compactMap(\.hardestIndex).max() ?? 0
        let minIndex = points.compactMap(\.hardestIndex).min() ?? 0
        return Chart {
            ForEach(points) { point in
                if let idx = point.hardestIndex {
                    LineMark(
                        x: .value("Month", point.month, unit: .month),
                        y: .value("Grade", idx)
                    )
                    .foregroundStyle(Brand.send)
                    .interpolationMethod(.monotone)

                    PointMark(
                        x: .value("Month", point.month, unit: .month),
                        y: .value("Grade", idx)
                    )
                    .foregroundStyle(Brand.send)
                }
            }
        }
        .chartYScale(domain: max(0, minIndex - 1)...(maxIndex + 1))
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intVal = value.as(Int.self),
                       let label = GradeScale.display(index: intVal, in: system) {
                        Text(label).font(Brand.mono(10))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
    }

    private func progressionAccessibility(_ points: [Analytics.MonthPoint]) -> String {
        let parts = points.compactMap { point -> String? in
            guard let idx = point.hardestIndex,
                  let label = GradeScale.display(index: idx, in: system) else { return nil }
            return "\(point.month.formatted(.dateTime.month(.abbreviated).year())): \(label)"
        }
        return "Hardest send by month. " + parts.joined(separator: ", ")
    }
}

#Preview {
    InsightsView()
        .environment(SettingsStore())
        .modelContainer(for: [Location.self, Climb.self, Session.self, Attempt.self], inMemory: true)
}
