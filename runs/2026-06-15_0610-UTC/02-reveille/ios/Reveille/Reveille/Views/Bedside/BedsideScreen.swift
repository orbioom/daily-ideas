import SwiftUI
import SwiftData

/// Bedside clock: a full-screen, tap-to-dim clock with the time, date, and next alarm. Uses
/// `TimelineView` so the seconds stay live without a manual timer. Theme is chosen in Settings
/// (Pro themes). Keeps the screen awake (per Settings) while shown.
struct BedsideScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var alarms: [Alarm]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var dimmed = false

    private var theme: BedsideTheme { settings.bedsideTheme(isPro: isPro) }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            ZStack {
                theme.gradient.ignoresSafeArea()
                Color.black.opacity(dimmed ? 0.55 : 0).ignoresSafeArea()

                VStack(spacing: 14) {
                    Spacer()
                    clock(now)
                    date(now)
                    Spacer()
                    nextAlarm(now)
                        .opacity(dimmed ? 0.35 : 1)
                    if !dimmed {
                        Text("Tap anywhere to dim")
                            .font(Theme.rounded(12))
                            .foregroundStyle(.white.opacity(0.55))
                            .padding(.bottom, 18)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 24)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.5)) { dimmed.toggle() }
                Haptics.tap(settings.hapticsEnabled)
            }
        }
        .statusBarHidden(dimmed)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = settings.keepScreenOn }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private func clock(_ now: Date) -> some View {
        Text(TimeFormat.clock(now, use24Hour: settings.use24Hour))
            .font(.system(size: 84, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(dimmed ? 0.85 : 1))
            .monospacedDigit()
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .shadow(color: .black.opacity(0.25), radius: 10, y: 3)
            .accessibilityLabel("Current time \(TimeFormat.clock(now, use24Hour: settings.use24Hour))")
    }

    private func date(_ now: Date) -> some View {
        Text(now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
            .font(Theme.rounded(20, .medium))
            .foregroundStyle(.white.opacity(dimmed ? 0.6 : 0.88))
    }

    @ViewBuilder
    private func nextAlarm(_ now: Date) -> some View {
        if let soonest = AlarmScheduler.soonestFire(alarms, reference: now) {
            HStack(spacing: 8) {
                Image(systemName: "alarm.fill").accessibilityHidden(true)
                Text("\(TimeFormat.clock(hour: soonest.alarm.hour, minute: soonest.alarm.minute, use24Hour: settings.use24Hour)) · \(AlarmScheduler.countdownLabel(to: soonest.date, from: now))")
            }
            .font(Theme.rounded(16, .semibold))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Capsule().fill(Color.white.opacity(0.16)))
            .accessibilityLabel("Next alarm at \(TimeFormat.clock(hour: soonest.alarm.hour, minute: soonest.alarm.minute, use24Hour: settings.use24Hour)), in \(AlarmScheduler.countdownLabel(to: soonest.date, from: now))")
        } else {
            Text("No alarm set")
                .font(Theme.rounded(15))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Capsule().fill(Color.white.opacity(0.12)))
        }
    }
}
