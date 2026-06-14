import SwiftUI
import SwiftData

/// Dashboard: latest reading, today's time-in-range, today's list, A1C mini card.
struct TodayScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Reading.date, order: .reverse) private var readings: [Reading]

    @State private var showAdd = false
    @State private var editingReading: Reading?

    private var todayReadings: [Reading] {
        let cal = Calendar.current
        return readings.filter { cal.isDateInToday($0.date) }
    }

    private var latest: Reading? { readings.first }

    private var todaySnapshot: GlucoseSnapshot {
        GlucoseEngine.compute(readings: todayReadings,
                              low: settings.safeLow,
                              high: settings.safeHigh)
    }

    /// A1C / GMI mini card uses all readings for a stable estimate.
    private var overallSnapshot: GlucoseSnapshot {
        GlucoseEngine.compute(readings: readings,
                              low: settings.safeLow,
                              high: settings.safeHigh)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if readings.isEmpty {
                    EmptyStateView(symbol: "drop",
                                   title: "No readings yet",
                                   message: "Log your first glucose reading to start building your private logbook.",
                                   actionTitle: "Log reading") { showAdd = true }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            latestCard
                            tirCard
                            if settings.showA1C {
                                a1cCard
                            }
                            todayListCard
                        }
                        .padding(16)
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle("Today")
            .safeAreaInset(edge: .bottom) {
                if !readings.isEmpty {
                    PrimaryButton(title: "Log reading", systemImage: "plus") { showAdd = true }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
            .sheet(isPresented: $showAdd) {
                AddReadingSheet()
            }
            .sheet(item: $editingReading) { r in
                AddReadingSheet(editing: r)
            }
        }
    }

    // MARK: Cards

    private var latestCard: some View {
        CardSection {
            if let latest {
                let band = settings.band(for: latest.valueMgdl)
                VStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: latest.context.symbol)
                            .accessibilityHidden(true)
                        Text(latest.context.label)
                    }
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.inkSoft)

                    Text(settings.formatValue(latest.valueMgdl))
                        .font(Theme.rounded(72, .bold))
                        .foregroundStyle(band.color)
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)

                    Text(settings.unit.label)
                        .font(Theme.rounded(16, .medium))
                        .foregroundStyle(Theme.inkSoft)

                    HStack(spacing: 6) {
                        Image(systemName: band.symbol).accessibilityHidden(true)
                        Text(band.rawValue)
                        Text("·")
                        Text(relativeTime(latest.date))
                    }
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(band.color)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Latest reading, \(latest.context.label)")
                .accessibilityValue("\(settings.accessibilityValue(latest.valueMgdl)), \(band.rawValue), \(relativeTime(latest.date))")
            }
        }
    }

    private var tirCard: some View {
        CardSection("Time in range · today") {
            if todayReadings.isEmpty {
                Text("No readings logged today yet.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                HStack(spacing: 18) {
                    TimeInRangeRing(fraction: todaySnapshot.timeInRange, size: 110)
                    VStack(alignment: .leading, spacing: 8) {
                        legendRow(.low, todaySnapshot.pctLow)
                        legendRow(.inRange, todaySnapshot.timeInRange)
                        legendRow(.high, todaySnapshot.pctHigh)
                        Text("\(todayReadings.count) reading\(todayReadings.count == 1 ? "" : "s") today")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkFaint)
                    }
                    Spacer()
                }
            }
        }
    }

    private func legendRow(_ band: GlucoseBand, _ fraction: Double) -> some View {
        HStack(spacing: 8) {
            Circle().fill(band.color).frame(width: 10, height: 10)
                .accessibilityHidden(true)
            Text(band.rawValue)
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text("\(Int((fraction * 100).rounded()))%")
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.inkSoft)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(band.rawValue): \(Int((fraction * 100).rounded())) percent")
    }

    private var a1cCard: some View {
        CardSection("Estimates") {
            HStack(spacing: 12) {
                estimateTile(String(format: "%.1f%%", overallSnapshot.estimatedA1C),
                             "Est. A1C", "heart.text.square.fill")
                Divider().frame(height: 44)
                estimateTile(String(format: "%.1f%%", overallSnapshot.gmi),
                             "GMI", "gauge.medium")
                Divider().frame(height: 44)
                estimateTile(settings.formatValue(overallSnapshot.averageMgdl),
                             "Avg \(settings.unit.label)", "chart.bar.fill")
            }
        }
    }

    private func estimateTile(_ value: String, _ label: String, _ symbol: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 15))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var todayListCard: some View {
        CardSection("Today's readings") {
            if todayReadings.isEmpty {
                Text("Nothing logged today.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                VStack(spacing: 0) {
                    ForEach(todayReadings) { r in
                        Button { editingReading = r } label: {
                            ReadingRow(reading: r)
                        }
                        .buttonStyle(.plain)
                        if r.id != todayReadings.last?.id {
                            Divider().overlay(Theme.hairline)
                        }
                    }
                }
            }
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .abbreviated
        return fmt.localizedString(for: date, relativeTo: Date())
    }
}
