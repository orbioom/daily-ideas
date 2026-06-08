import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Fast.start, order: .reverse) private var fasts: [Fast]

    @AppStorage("ember.activePlanName") private var planName = "16:8"
    @AppStorage("ember.activeGoalHours") private var goalHours = 16.0

    @State private var endingFast: Fast?
    @State private var showStartConfirm = false

    private var active: Fast? { fasts.first { $0.isActive } }
    private var lastCompleted: Fast? { fasts.first { $0.end != nil } }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 22) {
                        if let active {
                            activeContent(active)
                        } else {
                            idleContent
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Ember")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $endingFast) { fast in
            EndFastSheet(fast: fast)
        }
    }

    // MARK: - Active

    @ViewBuilder
    private func activeContent(_ fast: Fast) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let now = ctx.date
            let elapsed = fast.elapsed(now: now)
            let progress = FastEngine.progress(elapsed: elapsed, goalSeconds: fast.goalSeconds)
            let elapsedHours = elapsed / 3600
            let stage = FastEngine.currentStage(elapsedHours: elapsedHours)
            let overshoot = elapsed >= fast.goalSeconds
            let remaining = fast.goalSeconds - elapsed

            VStack(spacing: 22) {
                FastRing(progress: min(1, progress),
                         elapsedLabel: FastEngine.clock(elapsed),
                         captionTop: overshoot ? "GOAL REACHED" : "ELAPSED",
                         captionBottom: overshoot
                            ? "+\(FastEngine.hoursLabel(elapsed - fast.goalSeconds)) over goal"
                            : "\(FastEngine.clock(remaining)) to \(Int(fast.goalHours))h",
                         overshoot: overshoot)
                    .frame(height: 300)
                    .padding(.top, 8)

                stageCard(stage: stage, elapsedHours: elapsedHours, overshoot: overshoot)

                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Eyebrow(text: fast.planName)
                            Text("Started \(Format.dayTime.string(from: fast.start))")
                                .font(.subheadline)
                                .foregroundStyle(Brand.text2)
                        }
                        Spacer()
                        Image(systemName: "flame.fill")
                            .foregroundStyle(Color(hex: 0xB5552F))
                            .accessibilityHidden(true)
                    }
                }

                Button("End fast") {
                    fast.end = Date()
                    try? context.save()
                    Haptics.success()
                    endingFast = fast
                }
                .buttonStyle(InkButtonStyle())
            }
        }
    }

    @ViewBuilder
    private func stageCard(stage: FastStage, elapsedHours: Double, overshoot: Bool) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: stage.symbol)
                        .font(.title2)
                        .foregroundStyle(overshoot ? Brand.magic : Color(hex: 0xB5552F))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stage.title)
                            .font(.headline)
                            .foregroundStyle(Brand.text)
                        Text(stage.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                    }
                }
                if let next = FastEngine.nextStage(elapsedHours: elapsedHours) {
                    let hoursTo = next.startHour - elapsedHours
                    Divider().overlay(Brand.hairline)
                    HStack {
                        Text("Next: \(next.title)")
                            .font(.footnote)
                            .foregroundStyle(Brand.text2)
                        Spacer()
                        Text(hoursTo >= 1
                             ? "in \(String(format: "%.1f", hoursTo))h"
                             : "in \(Int(hoursTo * 60))m")
                            .font(Brand.mono(13))
                            .foregroundStyle(Brand.text3)
                    }
                }
            }
        }
    }

    // MARK: - Idle

    @ViewBuilder
    private var idleContent: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle().stroke(Brand.hairline, lineWidth: 18)
                VStack(spacing: 8) {
                    Image(systemName: "flame")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(Brand.text3)
                        .accessibilityHidden(true)
                    Text("Ready when you are")
                        .font(.headline)
                        .foregroundStyle(Brand.text2)
                }
            }
            .frame(height: 300)
            .padding(.top, 8)

            GlassCard {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Eyebrow(text: "SELECTED PLAN")
                        Text(planName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Brand.text)
                        Text("Fast \(Int(goalHours))h · eat \(Int(24 - goalHours))h")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                    }
                    Spacer()
                    Image(systemName: "target")
                        .foregroundStyle(Color(hex: 0xB5552F))
                        .accessibilityHidden(true)
                }
            }

            Button("Start \(planName) fast") {
                let fast = Fast(start: Date(), goalHours: goalHours, planName: planName)
                context.insert(fast)
                try? context.save()
                Haptics.success()
            }
            .buttonStyle(InkButtonStyle())

            if let last = lastCompleted {
                GlassCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow(text: "LAST FAST")
                        HStack {
                            Text("\(Format.hours(last.elapsedSeconds / 3600)) h")
                                .font(Brand.mono(20, weight: .semibold))
                                .foregroundStyle(Brand.text)
                            if last.didReachGoal {
                                Label("Goal hit", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Brand.live)
                            }
                            Spacer()
                            Text(Format.monthDay.string(from: last.end ?? last.start))
                                .font(.footnote)
                                .foregroundStyle(Brand.text3)
                        }
                    }
                }
            }
        }
    }
}
