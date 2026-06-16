import SwiftUI

/// Full-screen breathing player. A slowly breathing orb eased to the wall-clock
/// phase timeline, with a numeric/arc fallback under Reduce Motion.
struct BreatheView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(PrefKey.reduceVisualsExtra) private var reduceVisualsExtra = false
    @AppStorage(PrefKey.isPro) private var isPro = false

    @State private var engine: BreathEngine
    @State private var lastPhaseKind: BreathPhaseKind?
    @State private var showPaywall = false

    init(initialPattern: BreathPattern) {
        _engine = State(initialValue: BreathEngine(pattern: initialPattern))
    }

    /// True when the orb-scaling animation should be suppressed.
    private var staticMode: Bool { reduceMotion || reduceVisualsExtra }

    var body: some View {
        ZStack {
            HavenBackground()
            VStack(spacing: 0) {
                header
                Spacer()
                TimelineView(.animation(minimumInterval: staticMode ? 0.25 : 1.0 / 30.0, paused: !engine.isRunning)) { timeline in
                    let tick = engine.tick(at: timeline.date)
                    breathBody(tick)
                        .onChange(of: tick.kind) { _, newKind in
                            handlePhaseChange(to: newKind, tick: tick)
                        }
                }
                Spacer()
                patternPicker
                controls
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear { engine.start() }
        .onDisappear { engine.pause() }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(HavenTheme.secondaryText(scheme))
            }
            .accessibilityLabel("Close breathing")
            Spacer()
            Text("\(engine.minutesDone) min · \(engine.cyclesDone) breaths")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(HavenTheme.secondaryText(scheme))
                .accessibilityLabel("\(engine.minutesDone) minutes, \(engine.cyclesDone) breaths so far")
        }
        .padding(.top, 12)
    }

    // MARK: Breathing body

    @ViewBuilder
    private func breathBody(_ tick: BreathTick) -> some View {
        VStack(spacing: 28) {
            if staticMode {
                staticRing(tick)
            } else {
                animatedOrb(tick)
            }
            VStack(spacing: 6) {
                Text(tick.kind.word)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(HavenTheme.primaryText(scheme))
                    .contentTransition(.identity)
                Text("\(tick.secondsRemaining)")
                    .font(.system(size: 40, weight: .light, design: .rounded))
                    .foregroundStyle(HavenTheme.accentDeep)
                    .monospacedDigit()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(tick.kind.word), \(tick.secondsRemaining) seconds")
        }
    }

    private func animatedOrb(_ tick: BreathTick) -> some View {
        ZStack {
            Circle()
                .fill(HavenTheme.accent.opacity(0.12))
                .frame(width: 280, height: 280)
            Circle()
                .fill(HavenTheme.orbGradient)
                .frame(width: 240, height: 240)
                .scaleEffect(tick.scale)
                .shadow(color: HavenTheme.accent.opacity(0.4), radius: 30)
        }
        .accessibilityHidden(true)
    }

    /// Static ring fallback: no scaling, just a calm progress arc + word.
    private func staticRing(_ tick: BreathTick) -> some View {
        ZStack {
            Circle()
                .stroke(HavenTheme.subtleFill(scheme), lineWidth: 18)
                .frame(width: 240, height: 240)
            Circle()
                .trim(from: 0, to: max(0.001, tick.phaseProgress))
                .stroke(HavenTheme.accent, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .frame(width: 240, height: 240)
                .rotationEffect(.degrees(-90))
            Image(systemName: phaseSymbol(tick.kind))
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(HavenTheme.accentDeep)
        }
        .accessibilityHidden(true)
    }

    private func phaseSymbol(_ kind: BreathPhaseKind) -> String {
        switch kind {
        case .inhale: return "arrow.up.circle"
        case .exhale: return "arrow.down.circle"
        case .holdIn, .holdOut: return "pause.circle"
        }
    }

    // MARK: Pattern picker

    private var patternPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(BreathPattern.allCases) { pattern in
                    patternChip(pattern)
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(.bottom, 18)
    }

    private func patternChip(_ pattern: BreathPattern) -> some View {
        let locked = !pattern.isFree && !isPro
        let selected = engine.pattern == pattern
        return Button {
            if locked {
                showPaywall = true
            } else {
                engine.setPattern(pattern)
                engine.start()
                if hapticsEnabled { Haptics.selection() }
            }
        } label: {
            VStack(spacing: 3) {
                HStack(spacing: 5) {
                    Text(pattern.title).font(.subheadline.weight(.semibold))
                    if locked {
                        Image(systemName: "lock.fill").font(.caption2)
                    }
                }
                Text(pattern.subtitle).font(.caption2)
            }
            .foregroundStyle(selected ? .white : HavenTheme.primaryText(scheme))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if selected { AnyView(HavenTheme.sosGradient) }
                    else { AnyView(HavenTheme.subtleFill(scheme)) }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerSmall, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(pattern.title), \(pattern.subtitle)\(locked ? ", Haven Plus" : "")")
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 14) {
            Button {
                engine.reset()
                engine.start()
            } label: {
                Label("Restart", systemImage: "arrow.counterclockwise")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HavenTheme.accentDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(HavenTheme.subtleFill(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerMedium, style: .continuous))
            }
            .accessibilityHint("Restarts the breathing session")

            Button {
                engine.toggle()
                if hapticsEnabled { Haptics.selection() }
            } label: {
                Label(engine.isRunning ? "Pause" : "Resume",
                      systemImage: engine.isRunning ? "pause.fill" : "play.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(HavenTheme.sosGradient)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerMedium, style: .continuous))
            }
        }
    }

    // MARK: Phase change → haptic cue

    private func handlePhaseChange(to newKind: BreathPhaseKind, tick: BreathTick) {
        guard engine.isRunning else { return }
        guard lastPhaseKind != newKind else { return }
        lastPhaseKind = newKind
        guard hapticsEnabled else { return }
        switch newKind {
        case .inhale, .exhale: Haptics.soft()
        case .holdIn, .holdOut: Haptics.light()
        }
    }
}
