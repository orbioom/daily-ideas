import SwiftUI
import SwiftData

/// A single timer card with a live ring (driven by TimelineView) and controls.
struct TimerCard: View {
    @Bindable var timer: CookTimer

    @EnvironmentObject private var settings: AppSettings
    @Environment(TimerEngine.self) private var timerEngine
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Re-render once per second while active; static when paused/finished.
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let now = ctx.date
            let remaining = timer.remainingSeconds(at: now)
            let finished = timer.isActive && remaining <= 0

            VStack(spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    TimerRing(
                        progress: timer.progress(at: now),
                        remainingSeconds: remaining,
                        isFinished: finished,
                        diameter: 96
                    )
                    VStack(alignment: .leading, spacing: 6) {
                        Text(timer.label)
                            .font(Theme.roundedStyle(.headline, .bold))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(2)
                        Text(statusLine(remaining: remaining, finished: finished))
                            .font(Theme.roundedStyle(.subheadline, .medium))
                            .foregroundStyle(finished ? Theme.good : Theme.inkSoft)
                        if let foodId = timer.foodId, let food = FoodCatalog.byId[foodId] {
                            Label(Fmt.temp(fahrenheit: food.fresh.tempF, unit: settings.tempUnit),
                                  systemImage: "thermometer.medium")
                                .font(Theme.roundedStyle(.caption, .medium))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer(minLength: 0)
                    }
                    Spacer(minLength: 0)
                }
                controls(remaining: remaining, finished: finished)
            }
            .padding(16)
            .crispCard()
            .onChange(of: finished) { _, isDone in
                if isDone, timerEngine.registerCompletionIfNeeded(timer) {
                    Haptics.notify(.success, enabled: settings.hapticsEnabled)
                }
            }
            .accessibilityElement(children: .contain)
        }
    }

    private func statusLine(remaining: Int, finished: Bool) -> String {
        if finished { return "Done — take it out!" }
        if !timer.isActive { return "Paused · \(Fmt.clock(seconds: remaining)) left" }
        return "Cooking · \(Fmt.clock(seconds: remaining)) left"
    }

    @ViewBuilder
    private func controls(remaining: Int, finished: Bool) -> some View {
        if finished {
            HStack(spacing: 10) {
                PrimaryButton(title: "Done", systemImage: "checkmark") {
                    stop()
                }
            }
        } else {
            HStack(spacing: 10) {
                circleControl(symbol: "minus", label: "Subtract one minute") {
                    timerEngine.adjust(timer, by: -60, context: context, soundEnabled: true)
                    Haptics.selection(enabled: settings.hapticsEnabled)
                }
                circleControl(symbol: "plus", label: "Add one minute") {
                    timerEngine.adjust(timer, by: 60, context: context, soundEnabled: true)
                    Haptics.selection(enabled: settings.hapticsEnabled)
                }
                if timer.isActive {
                    pillControl(title: "Pause", symbol: "pause.fill") {
                        timerEngine.pause(timer, context: context)
                        Haptics.impact(.light, enabled: settings.hapticsEnabled)
                    }
                } else {
                    pillControl(title: "Resume", symbol: "play.fill") {
                        timerEngine.resume(timer, context: context, soundEnabled: true)
                        Haptics.impact(.light, enabled: settings.hapticsEnabled)
                    }
                }
                circleControl(symbol: "stop.fill", label: "Stop timer", tint: Theme.bad) {
                    stop()
                }
            }
        }
    }

    private func circleControl(symbol: String, label: String, tint: Color = Theme.accent, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .frame(width: 44, height: 44)
                .foregroundStyle(tint)
                .background(Circle().fill(Theme.surfaceAlt))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func pillControl(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(Theme.roundedStyle(.subheadline, .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Capsule().fill(Theme.accent))
        }
        .buttonStyle(.plain)
    }

    private func stop() {
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
        timerEngine.stop(timer, context: context)
    }
}
