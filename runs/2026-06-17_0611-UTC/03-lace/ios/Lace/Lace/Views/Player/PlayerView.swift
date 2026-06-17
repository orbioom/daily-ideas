import SwiftUI
import UIKit

/// The full-screen guided session player. A `TimelineView` re-reads the engine's
/// wall-clock-derived state ~4×/second; cues & completion are driven from an
/// `.onChange` on a quarter-second key so no observable state is mutated during
/// view-body evaluation. Survives backgrounding/relaunch because elapsed is
/// derived from a stored start `Date`.
struct PlayerView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings

    @Bindable var player: PlayerEngine
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            if player.state == .completed {
                CompletionView(player: player, isPresented: $isPresented)
            } else {
                TimelineView(.periodic(from: .now, by: 0.25)) { context in
                    RunningPlayerContent(player: player, isPresented: $isPresented, now: context.date)
                }
            }
        }
        .onAppear { applyKeepAwake(true) }
        .onDisappear {
            applyKeepAwake(false)
            // If dismissed without completing, release audio but keep the
            // persisted run so it can resume.
            if player.state != .completed { player.releaseAudio() }
        }
        .interactiveDismissDisabled(player.state == .running || player.state == .paused)
    }

    private var backgroundGradient: LinearGradient {
        let base = Theme.appBackground(scheme)
        return LinearGradient(
            colors: scheme == .dark
                ? [Theme.coralDeep.opacity(0.55), base]
                : [Theme.coralDeep, Theme.coral],
            startPoint: .top, endPoint: .bottom)
    }

    private func applyKeepAwake(_ active: Bool) {
        UIApplication.shared.isIdleTimerDisabled = active && settings.keepAwake
    }
}

/// The live running UI for one timeline frame. Display is pure; side effects
/// (spoken cues, beeps, completion) are driven by `.onChange` on a tick key.
private struct RunningPlayerContent: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Bindable var player: PlayerEngine
    @Binding var isPresented: Bool
    let now: Date

    @State private var showStopConfirm = false

    /// Quantised quarter-second key; changes drive the engine tick.
    private var tickKey: Int { Int(now.timeIntervalSinceReferenceDate * 4) }

    var body: some View {
        let interval = player.currentInterval(now: now)
        let kind = interval?.kind ?? .run
        let remaining = player.intervalRemaining(now: now)
        let overallProgress = player.overallProgress(now: now)

        VStack(spacing: 0) {
            topBar

            Spacer(minLength: 8)

            Text(kind.bigLabel)
                .font(Theme.display(46))
                .foregroundStyle(.white)
                .padding(.horizontal, 18).padding(.vertical, 8)
                .background(Capsule().fill(kind.color))
                .accessibilityHidden(true)

            intervalDial(kind: kind, remaining: remaining, progress: player.intervalProgress(now: now))
                .padding(.vertical, 24)

            nextUp

            Spacer(minLength: 8)

            overall(progress: overallProgress)

            controls
                .padding(.top, 18)
                .padding(.bottom, 8)
        }
        .padding(20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(kind.title), \(Fmt.spokenDuration(remaining)) remaining. Overall \(Fmt.percent(overallProgress)) complete.")
        .onAppear { player.tick(now: now) }
        .onChange(of: tickKey) { _, _ in player.tick(now: now) }
        .confirmationDialog("End this session?", isPresented: $showStopConfirm, titleVisibility: .visible) {
            Button("End workout", role: .destructive) {
                player.stop()
                isPresented = false
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("Your progress in this session won't be saved.")
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                if player.state == .running || player.state == .paused {
                    showStopConfirm = true
                } else {
                    player.stop()
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Circle().fill(.white.opacity(0.18)))
            }
            .accessibilityLabel("End session")
            Spacer()
            VStack(spacing: 1) {
                Text("Week \(player.week) · Session \(player.sessionIndex + 1)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.85))
                Text(PlanResolver.shared.plan(id: player.planId)?.title ?? "Session")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .accessibilityElement(children: .combine)
            Spacer()
            Image(systemName: "xmark").font(.headline).opacity(0).padding(10)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func intervalDial(kind: IntervalKind, remaining: Int, progress: Double) -> some View {
        ZStack {
            if reduceMotion {
                // Discrete fallback — no spinning trim; a static thick ring + numerals.
                Circle().stroke(.white.opacity(0.18), lineWidth: 16)
                Circle().stroke(.white.opacity(0.4), lineWidth: 16)
            } else {
                Circle().stroke(.white.opacity(0.18), lineWidth: 16)
                Circle()
                    .trim(from: 0, to: min(1, max(0, progress)))
                    .stroke(.white, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            VStack(spacing: 2) {
                Text(Fmt.clock(remaining))
                    .font(Theme.numeral(64))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("left in \(kind.title.lowercased())")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(width: 260, height: 260)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kind.title)")
        .accessibilityValue("\(Fmt.spokenDuration(remaining)) remaining")
    }

    @ViewBuilder
    private var nextUp: some View {
        if let next = player.nextInterval(now: now) {
            HStack(spacing: 8) {
                Image(systemName: next.kind.symbol).accessibilityHidden(true)
                Text("Next: \(next.kind.title) · \(Fmt.clock(next.durationSeconds))")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Capsule().fill(.white.opacity(0.16)))
            .accessibilityLabel("Up next: \(next.kind.title), \(Fmt.spokenDuration(next.durationSeconds))")
        } else {
            Label("Final interval", systemImage: "flag.checkered")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Capsule().fill(.white.opacity(0.16)))
        }
    }

    private func overall(progress: Double) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text("Total")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text("\(Fmt.clock(Int(player.elapsed(now: now)))) / \(Fmt.clock(player.totalSeconds))")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.9))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.2))
                    Capsule().fill(.white)
                        .frame(width: max(0, geo.size.width * min(1, max(0, progress))))
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Total progress")
        .accessibilityValue("\(Fmt.percent(progress)) complete, \(Fmt.spokenDuration(player.overallRemaining(now: now))) remaining")
    }

    private var controls: some View {
        HStack(spacing: 16) {
            if player.state == .running {
                Button { player.pause(); Haptics.tap(settings.hapticCues) } label: {
                    controlLabel("Pause", "pause.fill")
                }
                .accessibilityLabel("Pause")
            } else {
                Button { player.resume(); Haptics.tap(settings.hapticCues) } label: {
                    controlLabel("Resume", "play.fill")
                }
                .accessibilityLabel("Resume")
            }
            Button { showStopConfirm = true } label: {
                controlLabel("Stop", "stop.fill", filled: false)
            }
            .accessibilityLabel("Stop session")
        }
    }

    private func controlLabel(_ title: String, _ icon: String, filled: Bool = true) -> some View {
        Label(title, systemImage: icon)
            .font(.headline.weight(.bold))
            .foregroundStyle(filled ? Theme.coral : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(filled ? .white : .white.opacity(0.18))
            )
    }
}
