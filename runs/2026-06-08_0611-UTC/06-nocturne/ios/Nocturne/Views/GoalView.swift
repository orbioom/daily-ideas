import SwiftUI
import SwiftData

struct GoalView: View {
    @Query(sort: \SleepLog.wakeTime, order: .reverse) private var logs: [SleepLog]

    @AppStorage("nocturne.goalHours")  private var goalHours  = 8.0
    @AppStorage("nocturne.targetWake") private var targetWake = 420  // minutes of day
    @AppStorage("nocturne.clock24")    private var clock24    = false

    // Transient date for the time picker (not persisted directly — extracted to minutes)
    @State private var targetWakeDate: Date = Date()

    private var recommendedBedMinutes: Int {
        SleepEngine.recommendedBedtimeMinutes(targetWakeMinutes: targetWake, targetHours: goalHours)
    }

    private var debt: Double {
        SleepEngine.rollingDebt(logs: logs, targetHours: goalHours, window: 14)
    }

    private var regularityScore: Int {
        SleepEngine.regularityScore(logs: logs, lastN: 14)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                ScrollView {
                    VStack(spacing: 16) {
                        // Hero card: recommended bedtime
                        bedtimeHeroCard

                        // Goal hours editor
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Eyebrow(text: "Sleep Goal")

                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(Format.duration(goalHours))
                                            .font(Brand.mono(36, weight: .bold))
                                            .foregroundStyle(Brand.text)
                                            .contentTransition(.numericText())
                                            .animation(Brand.ease(0.25), value: goalHours)
                                        Text("target per night")
                                            .font(Brand.mono(12))
                                            .foregroundStyle(Brand.text3)
                                    }
                                    Spacer()
                                    Stepper("", value: $goalHours, in: 5.0...10.0, step: 0.25)
                                        .labelsHidden()
                                        .onChange(of: goalHours) { _, _ in Haptics.selection() }
                                        .accessibilityLabel("Goal hours: \(Format.duration(goalHours))")
                                        .accessibilityHint("Adjust in 15-minute steps")
                                }

                                // Range indicator
                                HStack {
                                    Text("5h")
                                        .font(Brand.mono(10))
                                        .foregroundStyle(Brand.text3)
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(Brand.hairline).frame(height: 6)
                                            Capsule()
                                                .fill(Brand.magic)
                                                .frame(
                                                    width: geo.size.width * ((goalHours - 5.0) / 5.0),
                                                    height: 6
                                                )
                                                .animation(Brand.ease(0.25), value: goalHours)
                                        }
                                    }
                                    .frame(height: 6)
                                    Text("10h")
                                        .font(Brand.mono(10))
                                        .foregroundStyle(Brand.text3)
                                }
                                .accessibilityHidden(true)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Target wake time editor
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Eyebrow(text: "Target Wake Time")

                                HStack {
                                    Text(Format.clockFromMinutes(targetWake, use24h: clock24))
                                        .font(Brand.mono(36, weight: .bold))
                                        .foregroundStyle(Brand.text)
                                        .animation(Brand.ease(0.25), value: targetWake)
                                    Spacer()
                                    DatePicker(
                                        "",
                                        selection: $targetWakeDate,
                                        displayedComponents: .hourAndMinute
                                    )
                                    .labelsHidden()
                                    .onChange(of: targetWakeDate) { _, newVal in
                                        let c = Calendar.current.dateComponents([.hour, .minute], from: newVal)
                                        let minutes = (c.hour ?? 7) * 60 + (c.minute ?? 0)
                                        targetWake = minutes
                                        Haptics.selection()
                                    }
                                    .accessibilityLabel("Target wake time: \(Format.clockFromMinutes(targetWake, use24h: clock24))")
                                }

                                Text("The time you aim to wake up on most mornings.")
                                    .font(.caption)
                                    .foregroundStyle(Brand.text3)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Debt + regularity summary
                        HStack(alignment: .top, spacing: 12) {
                            debtSummaryCard
                            regularitySummaryCard
                        }
                        .padding(.horizontal, 20)

                        // Explanation card
                        explanationCard
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Sleep Goal")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                syncTargetWakeDate()
            }
        }
    }

    // MARK: - Bedtime Hero

    private var bedtimeHeroCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "Recommended Bedtime Tonight")
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(Format.clockFromMinutes(recommendedBedMinutes, use24h: clock24))
                        .font(Brand.mono(44, weight: .bold))
                        .foregroundStyle(Brand.magic)
                        .contentTransition(.numericText())
                        .animation(Brand.ease(0.3), value: recommendedBedMinutes)

                    Spacer()

                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Brand.magic.opacity(0.7))
                        .accessibilityHidden(true)
                }
                Text("Wake at \(Format.clockFromMinutes(targetWake, use24h: clock24)) · \(Format.duration(goalHours)) goal")
                    .font(Brand.mono(13))
                    .foregroundStyle(Brand.text3)
            }
        }
        .padding(.horizontal, 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Recommended bedtime: \(Format.clockFromMinutes(recommendedBedMinutes, use24h: clock24)), to wake at \(Format.clockFromMinutes(targetWake, use24h: clock24)) with \(Format.duration(goalHours)) goal")
    }

    // MARK: - Debt Summary

    private var debtSummaryCard: some View {
        let debtColor: Color = debt <= 0 ? Brand.live : (debt < 3 ? Brand.warn : Brand.danger)
        return GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: "14-Night Debt")
                Text(debt <= 0 ? "0h" : Format.hoursDecimal(debt))
                    .font(Brand.mono(26, weight: .bold))
                    .foregroundStyle(debtColor)
                Text(SleepEngine.debtLabel(debt: debt))
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("14-night sleep debt: \(SleepEngine.debtLabel(debt: debt))")
    }

    // MARK: - Regularity Summary

    private var regularitySummaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: "Regularity")
                Text("\(regularityScore)")
                    .font(Brand.mono(26, weight: .bold))
                    .foregroundStyle(regularityScore >= 75 ? Brand.live : (regularityScore >= 45 ? Brand.warn : Brand.danger))
                Text("out of 100")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Regularity score: \(regularityScore) out of 100")
    }

    // MARK: - Explanation Card

    private var explanationCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow(text: "How It Works")

                explanationRow(
                    icon: "moon.zzz.fill",
                    iconColor: Brand.info,
                    title: "Sleep Debt",
                    body: "Each night you sleep less than your goal, you accumulate debt. Nocturne tracks the rolling total over 14 nights. Consistent oversleeping reduces it."
                )

                Divider().overlay(Brand.hairline)

                explanationRow(
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: Brand.magic,
                    title: "Regularity Score",
                    body: "Based on how consistent your bedtimes and wake times are. A score above 75 means your circadian rhythm is well-anchored."
                )

                Divider().overlay(Brand.hairline)

                explanationRow(
                    icon: "target",
                    iconColor: Brand.live,
                    title: "Recommended Bedtime",
                    body: "Computed by subtracting your goal from your target wake time. Follow it consistently to lower debt and raise your regularity score."
                )
            }
        }
    }

    private func explanationRow(icon: String, iconColor: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.text)
                Text(body)
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Helpers

    private func syncTargetWakeDate() {
        let h = targetWake / 60
        let m = targetWake % 60
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour   = h
        comps.minute = m
        comps.second = 0
        targetWakeDate = Calendar.current.date(from: comps) ?? Date()
    }
}
