import SwiftUI
import SwiftData

/// The sleep-timer screen: pick a duration + fade, start it, and watch a
/// full-screen countdown that survives backgrounding (driven by a stored end
/// Date + TimelineView). When it finishes, the engine fades to silence, playback
/// stops, and a ListeningSession is logged.
struct TimerView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Environment(SoundEngine.self) private var engine
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro
    @Environment(SleepTimer.self) private var sleepTimer

    @State private var selectedMinutes: Int = 45
    @State private var fadeSeconds: Double = 30
    @State private var showPaywall = false
    /// Captured when a timer starts, so a finished session can be logged.
    @State private var sessionStart: Date?
    @State private var sessionMixName: String = "Custom mix"

    /// Free tier: presets up to 60 min. Pro: longer + custom.
    private let freePresets = [15, 30, 45, 60]
    private let proPresets = [90, 120, 180, 480]

    var body: some View {
        NavigationStack {
            Group {
                if sleepTimer.isActive {
                    activeCountdown
                } else {
                    setupForm
                }
            }
            .hushScreenBackground(scheme)
            .navigationTitle("Sleep Timer")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onAppear {
                if !sleepTimer.isActive {
                    selectedMinutes = settings.defaultTimerMinutes
                    fadeSeconds = settings.fadeOutSeconds
                }
            }
        }
    }

    // MARK: - Setup

    private var setupForm: some View {
        ScrollView {
            VStack(spacing: 18) {
                HushCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HushSectionHeader(title: "Duration", systemImage: "clock")
                        durationGrid
                        Text("Selected: \(Formatting.minutesLabel(selectedMinutes))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(HushTheme.teal)
                    }
                }

                HushCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HushSectionHeader(title: "Fade out", systemImage: "dial.low")
                        HStack {
                            Text("Gentle taper")
                                .font(.subheadline)
                                .foregroundStyle(HushTheme.primaryText(scheme))
                            Spacer()
                            Text(fadeSeconds < 1 ? "Off" : "\(Int(fadeSeconds)) s")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(HushTheme.secondaryText(scheme))
                        }
                        Slider(value: $fadeSeconds, in: 0...maxFade, step: 5)
                            .tint(HushTheme.teal)
                            .accessibilityLabel("Fade out length")
                            .accessibilityValue(fadeSeconds < 1 ? "Off" : "\(Int(fadeSeconds)) seconds")
                        if !pro.isPro {
                            Text("Free fade up to \(Int(freeMaxFade)) s. Pro unlocks longer, gentler fades.")
                                .font(.caption2)
                                .foregroundStyle(HushTheme.secondaryText(scheme))
                        }
                    }
                }

                Button {
                    startTimer()
                } label: {
                    Label("Start sleep timer", systemImage: "moon.zzz.fill")
                }
                .buttonStyle(HushPrimaryButtonStyle())
                .disabled(!engine.hasActiveSound)

                if !engine.hasActiveSound {
                    Text("Pick at least one sound on the Mixer tab first.")
                        .font(.caption)
                        .foregroundStyle(HushTheme.secondaryText(scheme))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(16)
        }
        .scrollContentBackground(.hidden)
    }

    private var maxFade: Double { pro.isPro ? 300 : freeMaxFade }
    private var freeMaxFade: Double { 60 }

    private var durationGrid: some View {
        let columns = [GridItem(.adaptive(minimum: 84), spacing: 10)]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(freePresets, id: \.self) { m in
                durationChip(m, locked: false)
            }
            ForEach(proPresets, id: \.self) { m in
                durationChip(m, locked: !pro.isPro)
            }
        }
    }

    private func durationChip(_ minutes: Int, locked: Bool) -> some View {
        Button {
            if locked { showPaywall = true; return }
            selectedMinutes = minutes
            Haptics.tap(settings.hapticsEnabled)
        } label: {
            HStack(spacing: 4) {
                Text(Formatting.minutesLabel(minutes))
                if locked {
                    Image(systemName: "lock.fill").font(.caption2)
                }
            }
            .hushChip(selected: selectedMinutes == minutes && !locked)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Formatting.minutesLabel(minutes))
        .accessibilityValue(selectedMinutes == minutes ? "Selected" : (locked ? "Pro" : ""))
    }

    // MARK: - Active countdown

    private var activeCountdown: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            countdownContent(now: context.date)
                // Run timer side effects *after* the render pass (never mutate
                // state during view update). Re-evaluated each timeline tick.
                .onChange(of: context.date) { _, newDate in
                    handleTick(now: newDate)
                }
                .task(id: context.date) {
                    // Also handle the very first tick when the view appears.
                    handleTick(now: context.date)
                }
        }
    }

    private func countdownContent(now: Date) -> some View {
        let remaining = sleepTimer.remaining(at: now)
        let progress = sleepTimer.progress(at: now)
        let fading = sleepTimer.isFading(at: now)

        return VStack(spacing: 28) {
            Spacer()
            CountdownRing(progress: progress, fading: fading, label: Formatting.clock(remaining))
                .frame(width: 240, height: 240)

            VStack(spacing: 6) {
                Text(fading ? "Fading to silence…" : "Sleep well")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(fading ? HushTheme.amber : HushTheme.primaryText(scheme))
                Text("Playing \(sessionMixName)")
                    .font(.subheadline)
                    .foregroundStyle(HushTheme.secondaryText(scheme))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(Formatting.clock(remaining)) remaining\(fading ? ", fading out" : "")")

            Spacer()

            VStack(spacing: 12) {
                Button {
                    sleepTimer.extend(byMinutes: 15)
                    engine.cancelFadeRamp()
                    if !engine.isPlaying { engine.play() }
                    Haptics.tap(settings.hapticsEnabled)
                } label: {
                    Label("Add 15 minutes", systemImage: "plus.circle")
                }
                .buttonStyle(HushSecondaryButtonStyle())

                Button {
                    cancelTimer()
                } label: {
                    Label("Cancel timer", systemImage: "xmark.circle")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(HushTheme.danger)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .padding()
    }

    // MARK: - Tick handling

    private func handleTick(now: Date) {
        guard sleepTimer.isActive else { return }
        // Arm the engine fade once we cross into the fade window.
        if sleepTimer.isFading(at: now) && !sleepTimer.fadeArmed {
            let secs = max(0, sleepTimer.remaining(at: now))
            engine.beginFadeOut(seconds: Double(secs))
            sleepTimer.markFadeArmed()
        }
        // Finish.
        if sleepTimer.isFinished(at: now) {
            finishTimer(at: now)
        }
    }

    // MARK: - Actions

    private func startTimer() {
        guard engine.hasActiveSound else { return }
        if !engine.isPlaying { engine.play() }
        sessionStart = Date()
        sessionMixName = "Custom mix"
        sleepTimer.start(minutes: selectedMinutes, fade: pro.isPro ? fadeSeconds : min(freeMaxFade, fadeSeconds))
        Haptics.success(settings.hapticsEnabled)
    }

    private func cancelTimer() {
        logSessionIfNeeded(endedAt: Date())
        sleepTimer.cancel()
        engine.cancelFadeRamp()
        engine.stop()
        Haptics.tap(settings.hapticsEnabled)
    }

    private func finishTimer(at date: Date) {
        logSessionIfNeeded(endedAt: date)
        sleepTimer.cancel()
        engine.stop()
        engine.cancelFadeRamp()
    }

    private func logSessionIfNeeded(endedAt: Date) {
        guard let start = sessionStart else { return }
        let duration = Int(endedAt.timeIntervalSince(start))
        sessionStart = nil
        guard duration > 0 else { return }
        let sounds = engine.currentLayers.map { $0.type.rawValue }
        let session = ListeningSession(startedAt: start,
                                       durationSeconds: duration,
                                       mixName: sessionMixName,
                                       soundRaws: sounds)
        modelContext.insert(session)
        try? modelContext.save()
    }
}

// MARK: - Countdown ring

private struct CountdownRing: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let progress: Double
    let fading: Bool
    let label: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(HushTheme.track(scheme), lineWidth: 14)
            Circle()
                .trim(from: 0, to: max(0.0001, 1 - progress))
                .stroke(fading ? HushTheme.amber : HushTheme.teal,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                // A soft glow when active, suppressed under Reduce Motion.
                .shadow(color: reduceMotion ? .clear : (fading ? HushTheme.amber : HushTheme.teal).opacity(0.5),
                        radius: reduceMotion ? 0 : 10)
            VStack(spacing: 4) {
                Image(systemName: "moon.stars.fill")
                    .font(.title3)
                    .foregroundStyle(HushTheme.secondaryText(scheme))
                    .accessibilityHidden(true)
                Text(label)
                    .font(HushTheme.numeral(40))
                    .monospacedDigit()
                    .foregroundStyle(HushTheme.primaryText(scheme))
            }
        }
        .accessibilityHidden(true)
    }
}
