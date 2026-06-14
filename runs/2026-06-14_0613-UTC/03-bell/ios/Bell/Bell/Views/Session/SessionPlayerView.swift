import SwiftUI
import SwiftData

/// Full-screen immersive timer. Owns the SoundEngine + TimerEngine. On finish
/// (natural or early) it presents a reflection sheet which saves the session.
struct SessionPlayerView: View {
    let preset: Preset

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @StateObject private var engine = TimerEngine()
    @State private var sound = SoundEngine()

    @State private var halo = false
    @State private var showReflection = false
    @State private var showEndConfirm = false
    @State private var savedSeconds = 0
    @State private var didComplete = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: 36) {
                Spacer()
                phaseLabel
                haloAndClock
                Spacer()
                if engine.silentMode { silentNote }
                controls
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .onAppear { startSit() }
        .onChange(of: engine.phase) { _, phase in
            if phase == .complete && !showReflection {
                // Natural completion path.
                savedSeconds = engine.sittingSeconds
                didComplete = true
                showReflection = true
            }
        }
        .sheet(isPresented: $showReflection, onDismiss: { teardownAndClose() }) {
            ReflectionView(
                presetName: preset.name,
                seconds: savedSeconds,
                completedFully: didComplete
            ) { mood, note in
                save(mood: mood, note: note)
            }
            .interactiveDismissDisabled(true)
        }
        .alert("End this sit?", isPresented: $showEndConfirm) {
            Button("Keep sitting", role: .cancel) {
                if engine.phase == .paused { engine.resume() }
            }
            Button("End now", role: .destructive) { endEarly() }
        } message: {
            Text("Your time so far will be saved.")
        }
    }

    // MARK: - Background
    private var background: some View {
        LinearGradient(
            colors: [Theme.background, Theme.accentDeep.opacity(0.18), Theme.background],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Phase
    private var phaseLabel: some View {
        Text(engine.phaseLabel)
            .font(Theme.rounded(15, .semibold))
            .tracking(2)
            .textCase(.uppercase)
            .foregroundStyle(Theme.textSecondary)
            .accessibilityLabel("Phase: \(engine.phaseLabel)")
    }

    // MARK: - Halo + clock
    private var haloAndClock: some View {
        ZStack {
            // Breathing halo — static when Reduce Motion is on.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.accent.opacity(0.30), Theme.accent.opacity(0.02)],
                        center: .center, startRadius: 6, endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .scaleEffect(reduceMotion ? 1.0 : (halo ? 1.12 : 0.86))
                .opacity(engine.phase == .paused ? 0.4 : 1)
                .animation(
                    reduceMotion || engine.phase == .paused
                        ? nil
                        : .easeInOut(duration: 4).repeatForever(autoreverses: true),
                    value: halo
                )

            Circle()
                .strokeBorder(Theme.accent.opacity(0.25), lineWidth: 1.5)
                .frame(width: 230, height: 230)

            VStack(spacing: 6) {
                Text(timeString(engine.clockSeconds))
                    .font(Theme.rounded(58, .semibold).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
                if !engine.isOpenEnded {
                    Text("remaining")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.textTertiary)
                } else {
                    Text("elapsed")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(engine.isOpenEnded ? "Elapsed" : "Remaining")
            .accessibilityValue(timeString(engine.clockSeconds))
        }
        .onAppear { halo = true }
    }

    private var silentNote: some View {
        Label("Silent mode — bells play as a soft tap", systemImage: "speaker.slash")
            .font(Theme.rounded(13))
            .foregroundStyle(Theme.textTertiary)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Theme.surface.opacity(0.6))
            .clipShape(Capsule())
    }

    // MARK: - Controls
    private var controls: some View {
        HStack(spacing: 20) {
            Button {
                Haptics.impact(enabled: settings.hapticsEnabled)
                showEndConfirm = true
                if engine.phase != .paused { engine.pause() }
            } label: {
                controlLabel("End", "stop.fill", tint: Theme.danger)
            }
            .buttonStyle(.plain)

            Button {
                Haptics.impact(enabled: settings.hapticsEnabled)
                if engine.phase == .paused { engine.resume() } else { engine.pause() }
            } label: {
                controlLabel(engine.phase == .paused ? "Resume" : "Pause",
                             engine.phase == .paused ? "play.fill" : "pause.fill",
                             tint: Theme.accent)
            }
            .buttonStyle(.plain)
        }
    }

    private func controlLabel(_ title: String, _ symbol: String, tint: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
                .frame(width: 64, height: 64)
                .background(tint.opacity(0.14))
                .foregroundStyle(tint)
                .clipShape(Circle())
            Text(title)
                .font(Theme.rounded(13, .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
    }

    // MARK: - Lifecycle
    private func startSit() {
        engine.configure(sound: sound, settings: settings)
        engine.start(with: preset)
    }

    private func endEarly() {
        savedSeconds = engine.sittingSeconds
        _ = engine.endEarly()
        didComplete = false
        showReflection = true
    }

    private func save(mood: Mood, note: String) {
        let session = MeditationSession(
            date: Date(),
            durationSec: max(0, savedSeconds),
            presetName: preset.name,
            mood: mood,
            note: note,
            completedFully: didComplete
        )
        context.insert(session)
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
    }

    private func teardownAndClose() {
        engine.teardown()
        dismiss()
    }

    private func timeString(_ total: Int) -> String {
        let s = max(0, total)
        let m = s / 60, sec = s % 60
        return String(format: "%02d:%02d", m, sec)
    }
}
