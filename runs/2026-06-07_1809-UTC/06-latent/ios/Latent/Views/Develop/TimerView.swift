import SwiftUI
import SwiftData

/// The full-screen process timer. Reads everything it shows from the shared
/// TimerEngine, whose state is reconstructed from a persisted absolute end Date —
/// so the countdown is correct after backgrounding or relaunch. Respects Reduce
/// Motion (always shows a numeric countdown + linear MeterBar; the ring is decorative).
struct TimerView: View {
    @EnvironmentObject private var timer: TimerEngine
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("latent.tempUnit") private var tempUnitRaw = TempUnit.celsius.rawValue

    @State private var showCancelConfirm = false
    @State private var showSaveSheet = false

    private var tempUnit: TempUnit { TempUnit(rawValue: tempUnitRaw) ?? .celsius }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                if let phase = timer.currentPhase {
                    headerCard(phase: phase)
                    ringSection(phase: phase)
                    agitationCue(phase: phase)
                    nextPreview
                    controls
                } else if timer.didComplete {
                    // Brief state while the completion sheet comes up.
                    completionInterstitial
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .onAppear {
            timer.onAppear()
            if timer.didComplete { showSaveSheet = true }
        }
        .onDisappear { timer.onDisappear() }
        .onChange(of: timer.didComplete) { _, done in
            if done { showSaveSheet = true }
        }
        .confirmationDialog("Cancel this run?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
            Button("Cancel run", role: .destructive) {
                timer.cancel()
            }
            Button("Keep developing", role: .cancel) {}
        } message: {
            Text("The timer will stop and nothing will be logged.")
        }
        .sheet(isPresented: $showSaveSheet, onDismiss: {
            // If the user dismissed without saving, clear the completed state.
            if timer.didComplete { timer.finishAndClear() }
        }) {
            if let state = timer.state {
                SaveSessionView(state: state) {
                    timer.finishAndClear()
                }
            }
        }
    }

    // MARK: - Header

    private func headerCard(phase: Phase) -> some View {
        VStack(spacing: 8) {
            Eyebrow(text: phaseProgressLabel)
            HStack(spacing: 10) {
                Image(systemName: phase.kind.symbol)
                    .font(.title2)
                    .foregroundStyle(phase.kind == .develop ? Brand.magic : Brand.text)
                    .accessibilityHidden(true)
                Text(phase.kind.title)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Brand.text)
            }
            Text(phase.kind.hint)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
            if timer.isPaused {
                Badge(text: "Paused", color: Brand.warn)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private var phaseProgressLabel: String {
        guard let s = timer.state else { return "" }
        return "Phase \(s.currentIndex + 1) of \(s.phases.count)"
    }

    // MARK: - Ring + countdown

    private func ringSection(phase: Phase) -> some View {
        VStack(spacing: 18) {
            ZStack {
                if !reduceMotion {
                    // Decorative progress ring. Numeric countdown below is the
                    // source of truth; the ring is never the only cue.
                    Circle()
                        .stroke(Brand.hairline, lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: CGFloat(timer.phaseProgress))
                        .stroke(
                            (phase.kind == .develop ? Brand.magic : Brand.live),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(Brand.ease(0.9), value: timer.phaseProgress)
                }
                VStack(spacing: 4) {
                    Text(DevEngine.clock(timer.remainingSec))
                        .font(Brand.mono(reduceMotion ? 64 : 56, weight: .bold))
                        .foregroundStyle(Brand.text)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("remaining")
                        .font(Brand.mono(11, weight: .medium))
                        .tracking(1.2)
                        .foregroundStyle(Brand.text3)
                }
            }
            .frame(width: 240, height: 240)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(phase.kind.title) phase")
            .accessibilityValue("\(DevEngine.clock(timer.remainingSec)) remaining")

            // Linear bar shown always (and is the primary cue under Reduce Motion).
            VStack(spacing: 6) {
                MeterBar(fraction: timer.phaseProgress,
                         color: phase.kind == .develop ? Brand.magic : Brand.live,
                         height: 10)
                HStack {
                    Text("0:00")
                    Spacer()
                    Text(DevEngine.clock(phase.seconds))
                }
                .font(Brand.mono(11))
                .foregroundStyle(Brand.text3)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Agitation cue

    @ViewBuilder
    private func agitationCue(phase: Phase) -> some View {
        if phase.agitationEverySec > 0 {
            HStack(spacing: 12) {
                Image(systemName: "arrow.up.arrow.down.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Brand.info)
                    .scaleEffect((!reduceMotion && timer.agitationPulse) ? 1.25 : 1.0)
                    .animation(reduceMotion ? nil : Brand.ease(0.4), value: timer.agitationPulse)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Agitate every \(DevEngine.clock(phase.agitationEverySec))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.text)
                    Text("A gentle pulse and tap will remind you.")
                        .font(.footnote)
                        .foregroundStyle(Brand.text2)
                }
                Spacer()
            }
            .glassCard()
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - Next phase preview

    @ViewBuilder
    private var nextPreview: some View {
        if let next = timer.nextPhase {
            HStack(spacing: 12) {
                Image(systemName: next.kind.symbol)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .frame(width: 22)
                    .accessibilityHidden(true)
                Text("Next: \(next.kind.title)")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                Spacer()
                Text(DevEngine.clock(next.seconds))
                    .font(Brand.mono(14, weight: .medium))
                    .foregroundStyle(Brand.text)
            }
            .glassCard(padding: 14)
            .accessibilityElement(children: .combine)
        } else {
            HStack {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(Brand.live)
                    .accessibilityHidden(true)
                Text("Last phase — almost done.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                Spacer()
            }
            .glassCard(padding: 14)
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    timer.isPaused ? timer.resume() : timer.pause()
                } label: {
                    Label(timer.isPaused ? "Resume" : "Pause",
                          systemImage: timer.isPaused ? "play.fill" : "pause.fill")
                }
                .buttonStyle(InkButtonStyle())

                Button {
                    Haptics.tap()
                    timer.skip()
                } label: {
                    Label("Skip", systemImage: "forward.end.fill")
                }
                .buttonStyle(GlassButtonStyle())
            }

            Button(role: .destructive) {
                Haptics.tap()
                showCancelConfirm = true
            } label: {
                Label("Cancel run", systemImage: "xmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyle())
            .tint(Brand.danger)
        }
        .padding(.top, 4)
    }

    private var completionInterstitial: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(Brand.live)
            Text("Development complete")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.text)
            Text("Saving your session…")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .glassCard()
    }
}
