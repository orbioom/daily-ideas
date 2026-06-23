import SwiftUI

/// The live breathing screen: animated orb, phase cues, progress, and controls.
/// A ~30fps timer calls `engine.tick()` to recompute state outside of the view's
/// render pass (avoiding "modifying state during view update").
struct BreathingSessionView: View {
    @Bindable var engine: BreathEngine
    let accent: Color
    let reduceMotion: Bool
    var onClose: () -> Void
    var onFinish: () -> Void

    /// Display refresh timer; the engine itself derives time from `Date` anchors,
    /// so an occasional missed tick (e.g. backgrounding) self-corrects.
    private let ticker = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        content
            .onReceive(ticker) { _ in
                engine.tick()
            }
    }

    private var content: some View {
        VStack(spacing: Theme.Spacing.lg) {
            topBar
            Spacer()

            BreathingOrb(fill: engine.fill,
                         tint: accent,
                         reduceMotion: reduceMotion,
                         centerText: centerText,
                         caption: caption)
                .frame(height: 320)
                .padding(.horizontal, Theme.Spacing.lg)

            if reduceMotion {
                reduceMotionCue
            }

            Spacer()
            progressSection
            controls
                .padding(.bottom, Theme.Spacing.xl)
        }
        .onChange(of: engine.state) { _, newValue in
            if newValue == .finished { onFinish() }
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(engine.pattern.name).font(.headline).foregroundStyle(Theme.textPrimary)
                Text(engine.pattern.rhythmLabel).font(.caption.monospaced())
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.textSecondary)
            }
            .accessibilityLabel("End session")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.md)
    }

    private var centerText: String {
        if engine.state == .paused { return "Paused" }
        return "\(engine.segmentRemaining)"
    }

    private var caption: String {
        engine.currentSegment?.title ?? "Breathe"
    }

    private var reduceMotionCue: some View {
        VStack(spacing: 4) {
            Text(engine.currentSegment?.subtitle ?? "")
                .font(.title3.weight(.medium))
                .foregroundStyle(accent)
            Text("Follow the count above")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .accessibilityElement(children: .combine)
    }

    private var progressSection: some View {
        VStack(spacing: 6) {
            ProgressView(value: engine.fractionComplete)
                .tint(accent)
            HStack {
                Text(engine.currentSegment?.subtitle ?? "")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(engine.pattern.isRounds
                     ? "\(engine.unitsCompleted)/\(engine.pattern.roundCount) rounds"
                     : "\(engine.unitsCompleted) cycles")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var controls: some View {
        HStack(spacing: Theme.Spacing.xl) {
            Button {
                Haptics.shared.tap()
                engine.skipSegment()
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 56, height: 56)
                    .background(Theme.card, in: Circle())
            }
            .accessibilityLabel("Skip current phase")

            Button {
                Haptics.shared.tap()
                engine.togglePause()
            } label: {
                Image(systemName: engine.state == .running ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 76, height: 76)
                    .background(accent, in: Circle())
            }
            .accessibilityLabel(engine.state == .running ? "Pause" : "Resume")

            Button {
                Haptics.shared.tap()
                onClose()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.bad)
                    .frame(width: 56, height: 56)
                    .background(Theme.card, in: Circle())
            }
            .accessibilityLabel("Finish session")
        }
    }
}
