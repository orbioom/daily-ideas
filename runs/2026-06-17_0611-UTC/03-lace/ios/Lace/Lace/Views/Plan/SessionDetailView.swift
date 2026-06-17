import SwiftUI
import SwiftData

/// A full interval breakdown of one session, with a Start button.
struct SessionDetailView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings

    let plan: TrainingPlan
    let session: PlanSession
    let week: Int
    let index: Int
    @Bindable var player: PlayerEngine
    @Binding var showPlayer: Bool
    let isCompleted: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary header
                LaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Week \(week) · Session \(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Capsule().fill(Theme.coral))
                            Spacer()
                            if isCompleted {
                                Label("Completed", systemImage: "checkmark.seal.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Theme.positive)
                            }
                        }
                        Text(session.summary)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.primaryText(scheme))
                        HStack(spacing: 16) {
                            metric("clock", Fmt.minutes(session.totalSeconds), "Total")
                            metric("figure.run", Fmt.minutes(session.runSeconds), "Running")
                            metric("repeat", "\(session.runReps)", "Run reps")
                        }
                        IntervalStrip(intervals: session.intervals)
                    }
                }

                // Interval list
                LaceCard {
                    VStack(alignment: .leading, spacing: 0) {
                        LaceSectionHeader(title: "Intervals")
                            .padding(.bottom, 10)
                        ForEach(Array(session.intervals.enumerated()), id: \.element.id) { i, interval in
                            intervalRow(number: i + 1, interval: interval)
                            if i < session.intervals.count - 1 {
                                Divider().background(Theme.hairline(scheme))
                            }
                        }
                    }
                }

                Button {
                    start()
                } label: {
                    Label(isCompleted ? "Run it again" : "Start session", systemImage: "play.fill")
                }
                .buttonStyle(LacePrimaryButtonStyle())
            }
            .padding(20)
        }
        .laceScreenBackground(scheme)
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func metric(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(value, systemImage: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.primaryText(scheme))
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.secondaryText(scheme))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func intervalRow(number: Int, interval: Interval) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(interval.kind.color.opacity(0.18)).frame(width: 38, height: 38)
                Image(systemName: interval.kind.symbol)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(interval.kind.color)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(interval.kind.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.primaryText(scheme))
                Text("Step \(number) of \(session.intervals.count)")
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryText(scheme))
            }
            Spacer()
            Text(Fmt.clock(interval.durationSeconds))
                .font(Theme.numeral(18))
                .foregroundStyle(Theme.primaryText(scheme))
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(interval.kind.title), \(Fmt.spokenDuration(interval.durationSeconds))")
    }

    private func start() {
        player.voiceCuesEnabled = settings.voiceCuesEnabled
        player.countdownBeepsEnabled = settings.countdownBeeps
        player.hapticsEnabled = settings.hapticCues
        player.start(plan: plan, session: session, week: week, sessionIndex: index)
        Haptics.medium(settings.hapticCues)
        showPlayer = true
    }
}
