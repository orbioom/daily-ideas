import SwiftUI
import SwiftData

struct SessionPlayerView: View {
    let pattern: BreathPattern
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("lull.haptics") private var haptics = true
    @AppStorage("lull.keepAwake") private var keepAwake = true

    @State private var accumulated: Double = 0
    @State private var segmentStart: Date? = nil
    @State private var lastPhase: BreathPhase? = nil
    @State private var stage: Stage = .countIn
    @State private var countInStart = Date()
    private let countInLength: Double = 3

    private enum Stage { case countIn, breathing, done }

    var body: some View {
        ZStack {
            // Calm ink backdrop for focus.
            LinearGradient(colors: [Color(hex: 0x1A1C24), Color(hex: 0x0E0F14)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            switch stage {
            case .countIn: countInView
            case .breathing: breathingView
            case .done: doneView
            }
        }
        .statusBarHidden(true)
        .onAppear {
            startCountIn()
            UIApplication.shared.isIdleTimerDisabled = keepAwake
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    // MARK: Count-in
    private var countInView: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { ctx in
            let elapsed = max(0, ctx.date.timeIntervalSince(countInStart))
            let remaining = max(0, Int((countInLength - elapsed).rounded(.up)))
            VStack(spacing: 28) {
                Text("Get comfortable")
                    .font(.title2.weight(.semibold)).foregroundStyle(.white)
                Text("\(max(1, remaining))")
                    .font(Brand.mono(72, weight: .light)).foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text(pattern.name).font(.subheadline).foregroundStyle(.white.opacity(0.6))
            }
            .onChange(of: ctx.date) { _, _ in
                if stage == .countIn, elapsed >= countInLength { beginBreathing() }
            }
        }
    }

    // MARK: Breathing
    private var breathingView: some View {
        TimelineView(.animation(minimumInterval: 1.0/30.0)) { ctx in
            let elapsed = elapsed(now: ctx.date)
            let st = BreathEngine.state(for: pattern, elapsed: elapsed)
            content(st)
                .onChange(of: st.phase) { _, newPhase in
                    if haptics, lastPhase != nil { Haptics.selection() }
                    lastPhase = newPhase
                }
                .onChange(of: st.finished) { _, finished in
                    if finished { complete(elapsed: pattern.totalSeconds) }
                }
        }
    }

    private func content(_ st: BreathState) -> some View {
        VStack {
            HStack {
                Button { stopEarly() } label: {
                    Image(systemName: "xmark").font(.headline).foregroundStyle(.white.opacity(0.7))
                        .padding(10).background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("End session")
                Spacer()
                Text("Round \(st.round) / \(st.totalRounds)")
                    .font(Brand.mono(13)).foregroundStyle(.white.opacity(0.7))
            }
            .padding()

            Spacer()

            ZStack {
                BreathingOrb(scale: st.orbScale, tint: Brand.magic, reduceMotion: reduceMotion)
                VStack(spacing: 6) {
                    Text(st.phase.rawValue)
                        .font(.title2.weight(.medium)).foregroundStyle(.white)
                    Text("\(Int(st.phaseRemaining.rounded(.up)))")
                        .font(Brand.mono(34, weight: .light)).foregroundStyle(.white.opacity(0.85))
                        .monospacedDigit()
                }
            }
            .accessibilityElement()
            .accessibilityLabel("\(st.phase.rawValue), \(Int(st.phaseRemaining.rounded(.up))) seconds")

            Spacer()

            ProgressView(value: st.overallProgress)
                .tint(Brand.magic)
                .padding(.horizontal, 40)

            HStack(spacing: 16) {
                Button { togglePause() } label: {
                    Label(segmentStart == nil ? "Resume" : "Pause",
                          systemImage: segmentStart == nil ? "play.fill" : "pause.fill")
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 40).padding(.vertical, 24)
        }
    }

    // MARK: Done
    private var doneView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64)).foregroundStyle(Brand.magic)
            Text("Session complete")
                .font(.title.weight(.bold)).foregroundStyle(.white)
            Text("\(Format.minutes(min(accumulated, pattern.totalSeconds) / 60)) of calm")
                .font(.subheadline).foregroundStyle(.white.opacity(0.7))
            Button("Done") { dismiss() }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 60)
        }
    }

    // MARK: Logic
    private func startCountIn() {
        stage = .countIn
        countInStart = Date()
    }

    private func beginBreathing() {
        stage = .breathing
        accumulated = 0
        segmentStart = Date()
        lastPhase = nil
        if haptics { Haptics.success() }
    }

    private func elapsed(now: Date) -> Double {
        accumulated + (segmentStart.map { now.timeIntervalSince($0) } ?? 0)
    }

    private func togglePause() {
        if let start = segmentStart {
            accumulated += Date().timeIntervalSince(start)
            segmentStart = nil
        } else {
            segmentStart = Date()
        }
        if haptics { Haptics.tap() }
    }

    private func stopEarly() {
        let done = elapsed(now: Date())
        complete(elapsed: done)
    }

    private func complete(elapsed: Double) {
        guard stage == .breathing else { return }
        accumulated = min(elapsed, pattern.totalSeconds)
        segmentStart = nil
        let rounds = pattern.roundSeconds > 0 ? Int(accumulated / pattern.roundSeconds) : 0
        let session = BreathSession(patternName: pattern.name,
                                    plannedSeconds: pattern.totalSeconds,
                                    completedSeconds: accumulated,
                                    roundsCompleted: rounds)
        context.insert(session)
        try? context.save()
        if haptics { Haptics.success() }
        stage = .done
    }
}
