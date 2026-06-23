import SwiftUI

/// Floating rest-timer bar pinned to the bottom of the active workout. Uses a
/// TimelineView driven by the model's wall-clock end Date, so it stays accurate
/// across backgrounding. Fires a single completion haptic when it reaches zero.
struct RestTimerBar: View {
    @Bindable var timer: RestTimerModel
    let hapticsEnabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didNotifyDone = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let remaining = timer.remaining(at: context.date)
            let progress = timer.progress(at: context.date)
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Theme.cardStroke, lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Theme.rest, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "timer").font(.caption).foregroundStyle(Theme.rest)
                }
                .frame(width: 34, height: 34)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Rest").font(.caption2).foregroundStyle(Theme.textSecondary)
                    Text(Format.clock(remaining))
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText())
                }

                Spacer()

                Button { timer.add(seconds: -15) } label: {
                    Text("-15").font(.subheadline.weight(.semibold))
                        .frame(width: 46, height: 34)
                        .background(Theme.background, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Subtract 15 seconds")

                Button { timer.add(seconds: 15) } label: {
                    Text("+15").font(.subheadline.weight(.semibold))
                        .frame(width: 46, height: 34)
                        .background(Theme.background, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add 15 seconds")

                Button {
                    timer.stop()
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(Theme.background, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Stop rest timer")
            }
            .padding(12)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.cardStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.14), radius: 12, y: 6)
            .onChange(of: remaining <= 0.1) { _, done in
                if done && !didNotifyDone {
                    didNotifyDone = true
                    Haptics.notify(.success, enabled: hapticsEnabled)
                    timer.stop()
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Rest timer, \(Format.clock(remaining)) remaining")
        }
        .onAppear { didNotifyDone = false }
    }
}
