import SwiftUI
import SwiftData

struct TonightView: View {
    @Query(sort: \SleepLog.wakeTime, order: .reverse) private var logs: [SleepLog]
    @AppStorage("nocturne.goalHours")  private var goalHours  = 8.0
    @AppStorage("nocturne.targetWake") private var targetWake = 420   // minutes of day (7:00 AM)
    @AppStorage("nocturne.clock24")    private var clock24    = false

    @State private var showLogSheet = false

    private var lastNight: SleepLog? { logs.first }
    private var debt: Double {
        SleepEngine.rollingDebt(logs: logs, targetHours: goalHours, window: 14)
    }
    private var regularityScore: Int {
        SleepEngine.regularityScore(logs: logs, lastN: 14)
    }
    private var recommendedBedMinutes: Int {
        SleepEngine.recommendedBedtimeMinutes(targetWakeMinutes: targetWake, targetHours: goalHours)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                ScrollView {
                    VStack(spacing: 16) {
                        if let night = lastNight {
                            lastNightCard(night)
                        } else {
                            EmptyStateView(
                                icon: "moon.zzz",
                                title: "No logs yet",
                                message: "Log your first night's sleep to see your stats here."
                            )
                            .glassCard()
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                        }

                        // Debt gauge
                        GlassCard {
                            DebtGauge(
                                debt: debt,
                                label: SleepEngine.debtLabel(debt: debt)
                            )
                        }
                        .padding(.horizontal, 20)

                        // Regularity + recommended bedtime row
                        HStack(alignment: .top, spacing: 12) {
                            regularityCard
                            recommendedBedtimeCard
                        }
                        .padding(.horizontal, 20)

                        // Streak row
                        if !logs.isEmpty {
                            streakCard
                                .padding(.horizontal, 20)
                        }

                        // Log button
                        Button("Log Last Night's Sleep") {
                            Haptics.tap()
                            showLogSheet = true
                        }
                        .buttonStyle(InkButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                        .accessibilityHint("Open the sleep log form")
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Tonight")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showLogSheet) {
                LogSleepView()
            }
        }
    }

    // MARK: - Last Night Card

    @ViewBuilder
    private func lastNightCard(_ log: SleepLog) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Eyebrow(text: "Last night · \(Format.shortDate(log.nightDate))")
                    Spacer()
                    StarRatingDisplay(rating: log.quality)
                }

                HStack(alignment: .center, spacing: 20) {
                    DurationRing(
                        durationHours: log.durationHours,
                        goalHours: goalHours,
                        ringSize: 120
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        statRow(
                            label: "Duration",
                            value: Format.duration(log.durationHours),
                            color: Brand.text
                        )
                        statRow(
                            label: "vs Goal",
                            value: vsGoalString(log),
                            color: vsGoalColor(log)
                        )
                        statRow(
                            label: "Awakenings",
                            value: "\(log.awakenings)",
                            color: Brand.text
                        )
                        statRow(
                            label: "Bed",
                            value: Format.clock(log.bedTime, use24h: clock24),
                            color: Brand.text
                        )
                        statRow(
                            label: "Wake",
                            value: Format.clock(log.wakeTime, use24h: clock24),
                            color: Brand.text
                        )
                    }
                }

                if !log.tags.isEmpty {
                    TagChipsDisplay(tags: log.tags)
                }

                if !log.note.isEmpty {
                    Text(log.note)
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                        .italic()
                }
            }
        }
        .padding(.horizontal, 20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Last night's sleep: \(Format.duration(log.durationHours)), quality \(log.quality) out of 5")
    }

    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(Brand.mono(11, weight: .regular))
                .foregroundStyle(Brand.text3)
                .frame(width: 78, alignment: .leading)
            Text(value)
                .font(Brand.mono(13, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    private func vsGoalString(_ log: SleepLog) -> String {
        let delta = log.durationHours - goalHours
        if delta >= 0 { return "+\(Format.hoursDecimal(delta))" }
        return Format.hoursDecimal(delta)
    }

    private func vsGoalColor(_ log: SleepLog) -> Color {
        let delta = log.durationHours - goalHours
        if delta >= 0  { return Brand.live }
        if delta >= -1 { return Brand.warn }
        return Brand.danger
    }

    // MARK: - Regularity Card

    private var regularityCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "Regularity")
                ScoreDial(score: regularityScore, label: "score", dialSize: 90)
                    .frame(maxWidth: .infinity)
                Text(regularityLabel)
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var regularityLabel: String {
        if regularityScore >= 75 { return "Very consistent schedule" }
        if regularityScore >= 50 { return "Moderate consistency" }
        if regularityScore >= 25 { return "Irregular schedule" }
        return "Highly variable times"
    }

    // MARK: - Recommended Bedtime Card

    private var recommendedBedtimeCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "Bedtime")
                Text(Format.clockFromMinutes(recommendedBedMinutes, use24h: clock24))
                    .font(Brand.mono(26, weight: .bold))
                    .foregroundStyle(Brand.magic)
                Text("to wake at \(Format.clockFromMinutes(targetWake, use24h: clock24))\nwith \(Format.duration(goalHours)) goal")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Recommended bedtime: \(Format.clockFromMinutes(recommendedBedMinutes, use24h: clock24))")
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        let streak = SleepEngine.goalStreak(logs: logs, targetHours: goalHours)
        return GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Goal Streak")
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(streak)")
                            .font(Brand.mono(28, weight: .bold))
                            .foregroundStyle(streak > 0 ? Brand.live : Brand.text3)
                        Text(streak == 1 ? "night" : "nights")
                            .font(Brand.mono(14))
                            .foregroundStyle(Brand.text2)
                    }
                }
                Spacer()
                Image(systemName: streak > 0 ? "flame.fill" : "flame")
                    .font(.system(size: 30))
                    .foregroundStyle(streak > 0 ? Brand.warn : Brand.text3)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Goal streak: \(streak) consecutive night\(streak == 1 ? "" : "s") meeting your sleep goal")
    }
}
