import SwiftUI

struct PlayerView: View {
    var engine: BinauralEngine
    let preset: HaloPreset
    // moodBefore is stored in the engine's session info, passed via onBegin
    // We use @State to track it locally since PresetDetailView sets it
    @State var moodBefore: Int = 3

    @Environment(\.dismiss) private var dismiss
    @State private var showStopAlert = false
    @State private var showReflection = false
    @State private var completedDuration: TimeInterval = 0

    var body: some View {
        ZStack {
            // Cosmic background
            HaloTheme.background.ignoresSafeArea()

            // Subtle radial gradient behind ring
            RadialGradient(
                colors: [
                    preset.category.color.opacity(0.15),
                    HaloTheme.background
                ],
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar

                Spacer()

                // Central ring
                ZStack {
                    HaloRingView(color: preset.category.color, isPlaying: engine.isPlaying)
                        .frame(width: 280, height: 280)

                    // Center text
                    VStack(spacing: 8) {
                        Text(preset.name)
                            .font(HaloTheme.headlineFont)
                            .foregroundColor(HaloTheme.textPrimary)

                        Text(preset.binauralHzDisplay)
                            .font(HaloTheme.titleFont)
                            .foregroundColor(preset.category.color)
                            .shadow(color: preset.category.color.opacity(0.6), radius: 8)

                        timerDisplay
                    }
                }

                Spacer()

                // Progress
                progressSection

                Spacer(minLength: HaloTheme.spacingL)

                // Controls
                controlsSection

                // Volume
                volumeSection

                // Headphones reminder
                headphonesNote

                Spacer(minLength: HaloTheme.spacingM)
            }
            .padding(.horizontal, HaloTheme.spacingM)
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            // Set session completion callback
            engine.onSessionComplete = {
                completedDuration = engine.timerDuration
                showReflection = true
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .alert("End Session?", isPresented: $showStopAlert) {
            Button("End Session", role: .destructive) {
                completedDuration = engine.elapsedTime
                engine.stop()
                showReflection = true
            }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("Your progress will be saved.")
        }
        .sheet(isPresented: $showReflection) {
            ReflectionSheet(
                preset: preset,
                duration: completedDuration > 0 ? completedDuration : engine.elapsedTime,
                moodBefore: moodBefore,
                onSave: { _ in
                    dismiss()
                },
                onSkip: {
                    dismiss()
                }
            )
        }
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack {
            Button {
                if engine.isPlaying {
                    showStopAlert = true
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(HaloTheme.textTertiary)
            }
            Spacer()
            VStack(spacing: 2) {
                Text(preset.category.rawValue.uppercased())
                    .font(HaloTheme.captionFont)
                    .foregroundColor(preset.category.color)
                    .tracking(2)
            }
            Spacer()
            // Balance the X button
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.clear)
        }
        .padding(.top, HaloTheme.spacingM)
    }

    @ViewBuilder
    private var timerDisplay: some View {
        if let remaining = engine.remainingTime {
            Text(formatTime(remaining))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(HaloTheme.textSecondary)
        } else {
            Text(formatTime(engine.elapsedTime))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(HaloTheme.textTertiary)
        }
    }

    private var progressSection: some View {
        Group {
            if engine.timerDuration > 0 {
                let progress = min(engine.elapsedTime / engine.timerDuration, 1.0)
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 3)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [HaloTheme.primary, HaloTheme.accent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * progress, height: 3)
                        }
                    }
                    .frame(height: 3)

                    HStack {
                        Text(formatTime(engine.elapsedTime))
                            .font(HaloTheme.captionFont)
                            .foregroundColor(HaloTheme.textTertiary)
                        Spacer()
                        if let remaining = engine.remainingTime {
                            Text("-\(formatTime(remaining))")
                                .font(HaloTheme.captionFont)
                                .foregroundColor(HaloTheme.textTertiary)
                        }
                    }
                }
            }
        }
    }

    private var controlsSection: some View {
        HStack(spacing: HaloTheme.spacingXL) {
            // Stop
            Button {
                showStopAlert = true
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 24))
                    .foregroundColor(HaloTheme.textSecondary)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle().fill(HaloTheme.surface)
                    )
            }
            .buttonStyle(.plain)

            // Play/Pause
            Button {
                if engine.isPlaying {
                    engine.stop()
                } else {
                    engine.start(preset: preset)
                }
            } label: {
                Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 72, height: 72)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [HaloTheme.primary, HaloTheme.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: HaloTheme.accent.opacity(0.5), radius: 16)
                    )
            }
            .buttonStyle(.plain)

            // Spacer button for symmetry (restart or future feature)
            Button {
                // Future: restart session
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 24))
                    .foregroundColor(HaloTheme.textTertiary)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle().fill(HaloTheme.surface)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var volumeSection: some View {
        HStack(spacing: HaloTheme.spacingS) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 12))
                .foregroundColor(HaloTheme.textTertiary)

            Slider(
                value: Binding(
                    get: { Double(engine.volume) },
                    set: { engine.setVolume(Float($0)) }
                ),
                in: 0...1
            )
            .tint(HaloTheme.accent)

            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 12))
                .foregroundColor(HaloTheme.textTertiary)
        }
        .padding(.horizontal, HaloTheme.spacingXL)
        .padding(.top, HaloTheme.spacingM)
    }

    private var headphonesNote: some View {
        Label("Headphones required for binaural effect", systemImage: "headphones")
            .font(HaloTheme.captionFont)
            .foregroundColor(HaloTheme.textTertiary)
            .padding(.top, HaloTheme.spacingM)
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let s = Int(max(0, seconds))
        let m = s / 60
        let sec = s % 60
        return String(format: "%d:%02d", m, sec)
    }
}
