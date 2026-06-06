import SwiftUI
import SwiftData

/// The practice session screen: a metronome (tempo dial, tap tempo, start/stop), a
/// countdown timer that drives the block, and a spot checklist. On completion it
/// captures focus notes + quality and writes a `PracticeSession` to the log.
struct PracticeView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The piece this session is about. A session always has a piece (guarded).
    let piece: Piece

    @State private var metronome = Metronome()
    @State private var engine: PracticeSessionEngine
    @State private var workedSpots: Set<UUID> = []
    @State private var showingSummary = false
    @State private var focusNotes = ""
    @State private var quality: SessionQuality = .steady
    @State private var didSave = false

    init(piece: Piece) {
        self.piece = piece
        // Seed the engine from the user's default session length.
        _engine = State(initialValue: PracticeSessionEngine(targetMinutes: 25))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 22) {
                        timerCard
                        metronomeCard
                        spotChecklist
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }

                VStack {
                    Spacer()
                    transportBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }
            }
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { closeOut() }
                }
            }
            .onAppear(perform: configure)
            .onDisappear(perform: teardown)
            .onChange(of: engine.phase) { _, newPhase in
                if newPhase == .finished { handleFinished() }
            }
            .sheet(isPresented: $showingSummary, onDismiss: { if didSave { dismiss() } }) {
                summarySheet
            }
        }
        .interactiveDismissDisabled(engine.isActive)
    }

    // MARK: - Timer card

    private var timerCard: some View {
        GlassCard {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(piece.title)
                            .font(.headline)
                            .foregroundStyle(Brand.text)
                            .lineLimit(1)
                        Text("A4 = \(settings.referenceHz) Hz")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                    Spacer()
                    StatusBadge(status: piece.status)
                }

                Text(engine.remainingLabel)
                    .font(Brand.mono(56, weight: .semibold))
                    .foregroundStyle(engine.phase == .running ? Brand.text : Brand.text2)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .accessibilityLabel("Time remaining")
                    .accessibilityValue(spokenClock(engine.remainingSeconds))

                ProgressView(value: engine.progress)
                    .tint(Brand.live)

                if engine.phase == .idle {
                    Stepper(value: lengthBinding, in: SettingsStore.minSessionMinutes...SettingsStore.maxSessionMinutes, step: 5) {
                        HStack {
                            Text("Length")
                                .font(.subheadline)
                                .foregroundStyle(Brand.text2)
                            Spacer()
                            Text("\(engine.targetSeconds / 60) min")
                                .font(Brand.mono(15)).monospacedDigit()
                                .foregroundStyle(Brand.text)
                        }
                    }
                }
            }
        }
    }

    private var lengthBinding: Binding<Int> {
        Binding(
            get: { engine.targetSeconds / 60 },
            set: { engine.setTargetMinutes($0) }
        )
    }

    // MARK: - Metronome card

    private var metronomeCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                TempoDial(bpm: bpmBinding,
                          beatToggle: metronome.beatToggle,
                          isRunning: metronome.isRunning)

                HStack(spacing: 10) {
                    nudgeButton("-5", delta: -5)
                    nudgeButton("-1", delta: -1)
                    Button {
                        metronome.tap()
                        Haptics.impact(enabled: settings.hapticsEnabled, style: .soft)
                    } label: {
                        Text("Tap")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                    }
                    .buttonStyle(.bordered)
                    .tint(Brand.text)
                    .accessibilityHint("Tap repeatedly to set the tempo")
                    nudgeButton("+1", delta: 1)
                    nudgeButton("+5", delta: 5)
                }

                Button {
                    metronome.toggle()
                    Haptics.impact(enabled: settings.hapticsEnabled)
                } label: {
                    Label(metronome.isRunning ? "Stop metronome" : "Start metronome",
                          systemImage: metronome.isRunning ? "stop.fill" : "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.bordered)
                .tint(metronome.isRunning ? Brand.warm : Brand.live)
            }
        }
    }

    private func nudgeButton(_ label: String, delta: Int) -> some View {
        Button {
            metronome.nudge(delta)
        } label: {
            Text(label)
                .font(Brand.mono(14, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
        }
        .buttonStyle(.bordered)
        .tint(Brand.text2)
        .accessibilityLabel(delta > 0 ? "Increase tempo by \(delta)" : "Decrease tempo by \(-delta)")
    }

    private var bpmBinding: Binding<Int> {
        Binding(
            get: { metronome.bpm },
            set: { metronome.setBPM($0) }
        )
    }

    // MARK: - Spot checklist

    private var spotChecklist: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Spots to work")
            if piece.orderedSpots.isEmpty {
                GlassCard {
                    Text("No spots on this piece. You can still log time — add spots from the piece detail to track passages.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(piece.orderedSpots) { spot in
                    Button {
                        toggle(spot)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: workedSpots.contains(spot.id) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(workedSpots.contains(spot.id) ? Brand.live : Brand.text3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(spot.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Brand.text)
                                    .lineLimit(2)
                                if spot.targetTempo >= Tempo.min {
                                    Text("\(spot.currentTempo) → \(spot.targetTempo) BPM")
                                        .font(Brand.mono(12))
                                        .foregroundStyle(Brand.text3)
                                        .monospacedDigit()
                                }
                            }
                            Spacer()
                            MasteryDots(level: spot.clampedMastery)
                        }
                        .padding(14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityValue(workedSpots.contains(spot.id) ? "Worked" : "Not yet")
                    .accessibilityHint("Toggles whether you worked this spot")
                }
            }
        }
    }

    // MARK: - Transport

    private var transportBar: some View {
        HStack(spacing: 12) {
            switch engine.phase {
            case .idle:
                InkButton(title: "Start session", systemImage: "play.fill") {
                    engine.start()
                    Haptics.impact(enabled: settings.hapticsEnabled, style: .medium)
                }
            case .running:
                Button {
                    engine.pause()
                    Haptics.impact(enabled: settings.hapticsEnabled)
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity).frame(minHeight: 50)
                }
                .buttonStyle(.bordered).tint(Brand.text)
                Button {
                    engine.finish()
                } label: {
                    Label("Finish", systemImage: "checkmark")
                        .frame(maxWidth: .infinity).frame(minHeight: 50)
                        .foregroundStyle(.white)
                        .background(Brand.inkGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            case .paused:
                Button {
                    engine.resume()
                    Haptics.impact(enabled: settings.hapticsEnabled, style: .medium)
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .frame(maxWidth: .infinity).frame(minHeight: 50)
                        .foregroundStyle(.white)
                        .background(Brand.inkGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                Button {
                    engine.finish()
                } label: {
                    Label("Finish", systemImage: "checkmark")
                        .frame(maxWidth: .infinity).frame(minHeight: 50)
                }
                .buttonStyle(.bordered).tint(Brand.text)
            case .finished:
                InkButton(title: "Log this session", systemImage: "square.and.pencil") {
                    showingSummary = true
                }
            }
        }
    }

    // MARK: - Summary sheet

    private var summarySheet: some View {
        NavigationStack {
            Form {
                Section("This session") {
                    HStack {
                        Label("Practiced", systemImage: "clock")
                        Spacer()
                        Text(PracticeSessionEngine.clock(engine.elapsedSeconds))
                            .font(Brand.mono(16)).monospacedDigit()
                            .foregroundStyle(Brand.text)
                    }
                    HStack {
                        Label("Tempo", systemImage: "metronome")
                        Spacer()
                        Text("\(metronome.bpm) BPM")
                            .font(Brand.mono(16)).monospacedDigit()
                            .foregroundStyle(Brand.text2)
                    }
                }

                Section("How did it feel?") {
                    Picker("Quality", selection: $quality) {
                        ForEach(SessionQuality.allCases) { q in
                            Label(q.title, systemImage: q.systemImage).tag(q)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Focus notes") {
                    TextField("What did you work on?", text: $focusNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Log session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard", role: .destructive) {
                        showingSummary = false
                        engine.cancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveSession() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Lifecycle

    private func configure() {
        engine.setTargetMinutes(settings.defaultSessionMinutes)
        metronome.setBPM(piece.hasTarget ? piece.targetTempo : settings.defaultBPM)
        metronome.soundEnabled = settings.metronomeSoundEnabled
        metronome.hapticsEnabled = settings.hapticsEnabled
        // Pre-seed focus notes from worked spots later; nothing to do here yet.
    }

    private func teardown() {
        metronome.stop()
        if engine.isActive { engine.pause() }
    }

    private func toggle(_ spot: PracticeSpot) {
        if workedSpots.contains(spot.id) { workedSpots.remove(spot.id) }
        else { workedSpots.insert(spot.id) }
        Haptics.impact(enabled: settings.hapticsEnabled, style: .soft)
    }

    private func handleFinished() {
        metronome.stop()
        Haptics.success(enabled: settings.hapticsEnabled)
        if focusNotes.isEmpty {
            let worked = piece.orderedSpots.filter { workedSpots.contains($0.id) }.map { $0.name }
            if !worked.isEmpty {
                focusNotes = "Worked: " + worked.joined(separator: ", ")
            }
        }
        showingSummary = true
    }

    private func saveSession() {
        let saved = engine.writeSession(
            into: context,
            pieces: [piece],
            bpm: metronome.bpm,
            focusNotes: focusNotes,
            quality: quality
        )
        if saved != nil {
            didSave = true
            Haptics.success(enabled: settings.hapticsEnabled)
        }
        showingSummary = false
    }

    private func closeOut() {
        metronome.stop()
        engine.cancel()
        dismiss()
    }

    private func spokenClock(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m > 0 && s > 0 { return "\(m) minutes \(s) seconds" }
        if m > 0 { return "\(m) minutes" }
        return "\(s) seconds"
    }
}

#Preview {
    PracticeView(piece: PreviewData.samplePiece)
        .environment(SettingsStore())
        .previewContainer()
}
