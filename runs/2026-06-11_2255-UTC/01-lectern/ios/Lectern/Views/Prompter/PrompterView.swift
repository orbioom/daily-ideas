import SwiftUI
import SwiftData

/// The full-screen teleprompter stage. Always near-black like real prompter
/// glass; text rolls past a fixed guide line driven by `PrompterEngine`.
struct PrompterView: View {
    let script: Script

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("defaultWPM") private var defaultWPM = 150.0
    @AppStorage("prompterFontSize") private var fontSize = 34.0
    @AppStorage("countdownSeconds") private var countdownSeconds = 3
    @AppStorage("guideStyle") private var guideStyleRaw = GuideStyle.band.rawValue
    @AppStorage("mirrorHorizontal") private var mirrorHorizontal = false
    @AppStorage("mirrorVertical") private var mirrorVertical = false
    @AppStorage("keepAwake") private var keepAwake = true

    @State private var engine: PrompterEngine?
    @State private var controlsVisible = true
    @State private var contentHeight: CGFloat = 0
    @State private var sessionLogged = false
    @State private var dragAccumulator: CGFloat = 0

    enum GuideStyle: String, CaseIterable {
        case band, arrows, none
        var label: String {
            switch self {
            case .band: return "Band"
            case .arrows: return "Arrows"
            case .none: return "None"
            }
        }
    }

    private var guideStyle: GuideStyle { GuideStyle(rawValue: guideStyleRaw) ?? .band }

    /// Points of script per second so that the configured words-per-minute
    /// holds for this script's actual measured height.
    private func pointsPerSecond(forWPM wpm: Double) -> CGFloat {
        let words = Double(script.wordCount)
        guard words > 0, contentHeight > 0 else { return 60 }
        let totalSeconds = words / wpm * 60
        return contentHeight / CGFloat(totalSeconds)
    }

    var body: some View {
        GeometryReader { geo in
            let guideY = geo.size.height * 0.38
            ZStack {
                Theme.stage.ignoresSafeArea()

                if let engine {
                    TimelineView(.animation(paused: engine.phase != .playing)) { timeline in
                        scriptColumn(width: geo.size.width)
                            .offset(y: guideY - engine.offset(at: timeline.date))
                    }
                    .scaleEffect(x: mirrorHorizontal ? -1 : 1, y: mirrorVertical ? -1 : 1)
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black, location: 0.07),
                                .init(color: .black, location: 0.9),
                                .init(color: .clear, location: 1),
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                    guideOverlay(guideY: guideY, width: geo.size.width)

                    if engine.phase == .countingDown {
                        CountdownOverlay(seconds: countdownSeconds, reduceMotion: reduceMotion) {
                            engine.beginPlaying()
                            scheduleCompletion()
                        }
                    }

                    if engine.phase == .finished {
                        finishedOverlay
                    }

                    controlsLayer(engine: engine, geo: geo)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                    controlsVisible.toggle()
                }
            }
            .gesture(seekGesture)
        }
        .statusBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear {
            let e = PrompterEngine(pointsPerSecond: 60)
            engine = e
            script.lastPlayedAt = .now
            if keepAwake { UIApplication.shared.isIdleTimerDisabled = true }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            logSessionIfMeaningful()
        }
    }

    // MARK: - Script content

    private func scriptColumn(width: CGFloat) -> some View {
        VStack(alignment: .center, spacing: fontSize * 0.8) {
            ForEach(Array(script.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .font(.system(size: fontSize, weight: .medium, design: .serif))
                    .foregroundStyle(.white.opacity(0.94))
                    .multilineTextAlignment(.center)
                    .lineSpacing(fontSize * 0.32)
            }
            // Trailing spacer text so the last line scrolls up to the guide.
            Color.clear.frame(height: 240)
        }
        .padding(.horizontal, max(24, width * 0.08))
        .frame(width: width)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { updateHeight(proxy.size.height) }
                    .onChange(of: proxy.size.height) { _, newValue in updateHeight(newValue) }
            }
        )
    }

    private func updateHeight(_ h: CGFloat) {
        contentHeight = h
        engine?.totalDistance = max(0, h - 120)
        engine?.setSpeed(pointsPerSecond(forWPM: defaultWPM))
    }

    // MARK: - Guide

    @ViewBuilder
    private func guideOverlay(guideY: CGFloat, width: CGFloat) -> some View {
        switch guideStyle {
        case .band:
            Rectangle()
                .fill(Theme.accent.opacity(0.12))
                .frame(height: fontSize * 2.1)
                .overlay(Rectangle().fill(Theme.accent.opacity(0.55)).frame(height: 1.5), alignment: .top)
                .overlay(Rectangle().fill(Theme.accent.opacity(0.55)).frame(height: 1.5), alignment: .bottom)
                .position(x: width / 2, y: guideY + fontSize * 0.7)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        case .arrows:
            HStack {
                Image(systemName: "arrowtriangle.right.fill")
                Spacer()
                Image(systemName: "arrowtriangle.left.fill")
            }
            .font(.system(size: 22))
            .foregroundStyle(Theme.accent.opacity(0.8))
            .padding(.horizontal, 6)
            .position(x: width / 2, y: guideY + fontSize * 0.7)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        case .none:
            EmptyView()
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private func controlsLayer(engine: PrompterEngine, geo: GeometryProxy) -> some View {
        VStack {
            if controlsVisible {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.white.opacity(0.12), in: Circle())
                    }
                    .accessibilityLabel("Close prompter")
                    Spacer()
                    Text(script.title)
                        .font(.system(.subheadline, design: .serif, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                    Spacer()
                    Menu {
                        Toggle(isOn: $mirrorHorizontal) { Label("Mirror horizontally", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right") }
                        Toggle(isOn: $mirrorVertical) { Label("Flip vertically", systemImage: "arrow.up.and.down.righttriangle.up.righttriangle.down") }
                        Picker("Guide", selection: $guideStyleRaw) {
                            ForEach(GuideStyle.allCases, id: \.rawValue) { style in
                                Text(style.label).tag(style.rawValue)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.white.opacity(0.12), in: Circle())
                    }
                    .accessibilityLabel("Display options")
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .transition(.opacity)
            }

            Spacer()

            if controlsVisible {
                TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
                    transportPanel(engine: engine, now: timeline.date)
                }
                .transition(.opacity)
            }
        }
    }

    private func transportPanel(engine: PrompterEngine, now: Date) -> some View {
        VStack(spacing: 14) {
            ProgressView(value: min(1, max(0, engine.progress(at: now))))
                .tint(Theme.accent)
                .accessibilityLabel("Script progress")
                .accessibilityValue("\(Int(engine.progress(at: now) * 100)) percent")

            HStack {
                Text(TextStats.formatDuration(engine.elapsedPlayTime(at: now)))
                    .monospacedDigit()
                Spacer()
                Text("−" + TextStats.formatDuration(max(0, engine.estimatedTotalSeconds - Double(engine.offset(at: now) / max(engine.pointsPerSecond, 1)))))
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 22) {
                speedControl(engine: engine)
                Spacer()
                Button {
                    Haptics.tap()
                    switch engine.phase {
                    case .ready, .finished:
                        engine.beginCountdown()
                    case .paused:
                        engine.beginPlaying()
                        scheduleCompletion()
                    case .playing:
                        engine.pause()
                    case .countingDown:
                        break
                    }
                } label: {
                    Image(systemName: engine.phase == .playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Theme.stage)
                        .frame(width: 64, height: 64)
                        .background(Theme.accent, in: Circle())
                }
                .accessibilityLabel(engine.phase == .playing ? "Pause" : "Play")
                Spacer()
                fontControl
            }

            Button {
                engine.restart()
                Haptics.tap()
            } label: {
                Label("Restart", systemImage: "arrow.counterclockwise")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .accessibilityHint("Returns to the top of the script")
        }
        .padding(18)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    private func speedControl(engine: PrompterEngine) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 10) {
                Button {
                    adjustWPM(-10, engine: engine)
                } label: {
                    Image(systemName: "minus.circle.fill").font(.title3)
                }
                .accessibilityLabel("Slower")
                Text("\(Int(defaultWPM))")
                    .font(.headline.monospacedDigit())
                    .frame(minWidth: 40)
                Button {
                    adjustWPM(10, engine: engine)
                } label: {
                    Image(systemName: "plus.circle.fill").font(.title3)
                }
                .accessibilityLabel("Faster")
            }
            .foregroundStyle(.white.opacity(0.85))
            Text("wpm").font(.caption2).foregroundStyle(.white.opacity(0.5))
        }
        .accessibilityElement(children: .contain)
    }

    private var fontControl: some View {
        VStack(spacing: 4) {
            HStack(spacing: 10) {
                Button {
                    fontSize = max(20, fontSize - 2)
                    Haptics.tap()
                } label: {
                    Image(systemName: "textformat.size.smaller").font(.title3)
                }
                .accessibilityLabel("Smaller text")
                Button {
                    fontSize = min(64, fontSize + 2)
                    Haptics.tap()
                } label: {
                    Image(systemName: "textformat.size.larger").font(.title3)
                }
                .accessibilityLabel("Larger text")
            }
            .foregroundStyle(.white.opacity(0.85))
            Text("\(Int(fontSize)) pt").font(.caption2).foregroundStyle(.white.opacity(0.5))
        }
    }

    private var finishedOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("End of script")
                .font(.system(.title2, design: .serif, weight: .bold))
                .foregroundStyle(.white)
            if let engine {
                Text("Read \(script.wordCount) words in \(TextStats.formatDuration(engine.elapsedPlayTime(at: .now)))")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            HStack(spacing: 14) {
                Button {
                    engine?.restart()
                } label: {
                    Label("Again", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .background(.white.opacity(0.14), in: Capsule())
                        .foregroundStyle(.white)
                }
                Button {
                    dismiss()
                } label: {
                    Label("Done", systemImage: "checkmark")
                        .font(.headline)
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .background(Theme.accent, in: Capsule())
                        .foregroundStyle(Theme.stage)
                }
            }
            .padding(.top, 6)
        }
        .padding(30)
        .background(.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .padding(.horizontal, 30)
    }

    // MARK: - Gestures & helpers

    private var seekGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard let engine else { return }
                let delta = -(value.translation.height - dragAccumulator)
                dragAccumulator = value.translation.height
                engine.seek(by: delta * (mirrorVertical ? -1 : 1))
            }
            .onEnded { _ in dragAccumulator = 0 }
    }

    private func adjustWPM(_ delta: Double, engine: PrompterEngine) {
        defaultWPM = max(60, min(300, defaultWPM + delta))
        engine.setSpeed(pointsPerSecond(forWPM: defaultWPM))
        Haptics.tap()
    }

    /// Watches for the engine reaching the end while playing.
    private func scheduleCompletion() {
        Task { @MainActor in
            while let engine, engine.phase == .playing {
                let now = Date.now
                if engine.offset(at: now) >= engine.totalDistance - 0.5 {
                    engine.finish(at: now)
                    Haptics.success()
                    logSessionIfMeaningful()
                    break
                }
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }

    private func logSessionIfMeaningful() {
        guard let engine, !sessionLogged else { return }
        let elapsed = engine.elapsedPlayTime(at: .now)
        guard elapsed >= 5 else { return }
        sessionLogged = true
        let fraction = engine.totalDistance > 0 ? Double(engine.offset(at: .now) / engine.totalDistance) : 0
        let session = RehearsalSession(
            duration: elapsed,
            wordsRead: Int(Double(script.wordCount) * min(1, fraction)),
            completed: engine.phase == .finished,
            script: script
        )
        context.insert(session)
    }
}

private struct CountdownOverlay: View {
    let seconds: Int
    let reduceMotion: Bool
    let onDone: () -> Void
    @State private var remaining: Int = 0

    var body: some View {
        Text(remaining > 0 ? "\(remaining)" : "Go")
            .font(.system(size: 110, weight: .bold, design: .serif))
            .foregroundStyle(Theme.accent)
            .contentTransition(reduceMotion ? .identity : .numericText(countsDown: true))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black.opacity(0.6))
            .task {
                remaining = seconds
                while remaining > 0 {
                    try? await Task.sleep(for: .seconds(1))
                    withAnimation(reduceMotion ? nil : .snappy) { remaining -= 1 }
                }
                onDone()
            }
            .accessibilityLabel("Starting in \(remaining) seconds")
    }
}
