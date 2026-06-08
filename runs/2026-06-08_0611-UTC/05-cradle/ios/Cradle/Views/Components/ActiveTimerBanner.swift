import SwiftUI

/// Prominent live-timer banner shown at the top of HomeView when an event is
/// ongoing. Uses TimelineView for a battery-efficient ticking display.
struct ActiveTimerBanner: View {
    let event: CareEvent
    let onStop: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(event.kind.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: event.kind.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(event.kind.color)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        StatusDot(color: event.kind.color)
                        Text("\(event.kind.label) in progress")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Brand.text)
                    }

                    TimelineView(.periodic(from: .now, by: 1)) { ctx in
                        let dur = CradleEngine.duration(event: event, now: ctx.date)
                        Text(Format.duration(dur))
                            .font(Brand.mono(20, weight: .bold))
                            .foregroundStyle(event.kind.color)
                            .contentTransition(reduceMotion ? .identity : .numericText())
                            .accessibilityLabel("Duration: \(Format.duration(dur))")
                    }
                }

                Spacer()

                Button(action: onStop) {
                    Text("Stop")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(event.kind.color, in: Capsule())
                }
                .accessibilityLabel("Stop \(event.kind.label) timer")
                .accessibilityHint("Saves and ends the current \(event.kind.label) session")
            }
        }
    }
}
