import SwiftUI
import SwiftData
import Charts

/// Metronome screen: big BPM readout, transport, time-signature & subdivision
/// pickers, accent toggle, tap tempo, animated beat indicator, presets, and a
/// practice-minutes Charts summary.
struct MetronomeView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(MetronomeEngine.self) private var metronome
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \MetronomePreset.createdAt) private var presets: [MetronomePreset]

    @AppStorage("isPro") private var isPro: Bool = false
    @AppStorage("hapticOnBeat") private var hapticOnBeat: Bool = true
    @AppStorage("metronomeClickStyle") private var clickStyleRaw: String = ClickStyle.classic.rawValue

    @State private var showPaywall = false
    @State private var showSavePreset = false
    @State private var presetName = ""
    @State private var practiceStart: Date?

    private var clickStyle: ClickStyle { ClickStyle(rawValue: clickStyleRaw) ?? .classic }

    var body: some View {
        NavigationStack {
            ZStack {
                PitchTheme.appBackground(scheme).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        bpmCard
                        beatCard
                        configCard
                        presetsCard
                        practiceCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Metronome")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            metronome.hapticsEnabled = hapticOnBeat
            metronome.clickStyle = clickStyle
            metronome.onClick = { _, _, accent in
                if hapticOnBeat { Haptics.beat(true, accent: accent) }
            }
        }
        .onDisappear { stopAndLog() }
        .onChange(of: hapticOnBeat) { _, v in metronome.hapticsEnabled = v }
        .onChange(of: clickStyleRaw) { _, _ in metronome.clickStyle = clickStyle }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .alert("Save preset", isPresented: $showSavePreset) {
            TextField("Preset name", text: $presetName)
            Button("Save") { savePreset() }
            Button("Cancel", role: .cancel) { presetName = "" }
        } message: {
            Text("Save the current tempo, meter, and subdivision.")
        }
    }

    // MARK: - BPM card

    private var bpmCard: some View {
        PitchCard {
            VStack(spacing: 14) {
                Text("\(metronome.bpm)")
                    .font(PitchTheme.mono(64, weight: .bold))
                    .foregroundStyle(PitchTheme.primaryText(scheme))
                    .contentTransition(.numericText())
                    .accessibilityLabel("Tempo")
                    .accessibilityValue("\(metronome.bpm) beats per minute")
                Text("BPM")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PitchTheme.secondaryText(scheme))
                    .tracking(2)

                // Tempo slider + fine steppers.
                Slider(value: Binding(
                    get: { Double(metronome.bpm) },
                    set: { metronome.bpm = Int($0.rounded()) }
                ), in: Double(MetronomeEngine.minBPM)...Double(MetronomeEngine.maxBPM), step: 1)
                .tint(PitchTheme.indigo)
                .accessibilityLabel("Tempo slider")
                .accessibilityValue("\(metronome.bpm) BPM")

                HStack(spacing: 12) {
                    Button { adjustBPM(-1) } label: {
                        Image(systemName: "minus").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PitchSecondaryButtonStyle())
                    .accessibilityLabel("Decrease tempo")

                    Button(action: toggleTransport) {
                        Label(metronome.isPlaying ? "Stop" : "Start",
                              systemImage: metronome.isPlaying ? "stop.fill" : "play.fill")
                    }
                    .buttonStyle(PitchPrimaryButtonStyle())

                    Button { adjustBPM(1) } label: {
                        Image(systemName: "plus").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PitchSecondaryButtonStyle())
                    .accessibilityLabel("Increase tempo")
                }

                Button(action: tap) {
                    Label("Tap tempo", systemImage: "hand.tap.fill")
                }
                .buttonStyle(PitchSecondaryButtonStyle())
            }
        }
    }

    // MARK: - Beat indicator card

    private var beatCard: some View {
        PitchCard {
            VStack(spacing: 12) {
                PitchSectionHeader(title: "Beat", systemImage: "waveform.path")
                BeatIndicator(beatCount: metronome.timeSignature.top,
                              activeBeat: metronome.currentBeat,
                              accentFirst: metronome.accentFirst)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                Text(metronome.timeSignature.label + " · " + metronome.subdivision.label)
                    .font(PitchTheme.mono(14))
                    .foregroundStyle(PitchTheme.secondaryText(scheme))
            }
        }
    }

    // MARK: - Config card

    private var configCard: some View {
        PitchCard {
            VStack(alignment: .leading, spacing: 16) {
                PitchSectionHeader(title: "Time signature", systemImage: "music.note")
                meterPicker
                PitchSectionHeader(title: "Subdivision", systemImage: "metronome")
                subdivisionPicker
                Toggle(isOn: Binding(
                    get: { metronome.accentFirst },
                    set: { metronome.accentFirst = $0 }
                )) {
                    Text("Accent first beat")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(PitchTheme.primaryText(scheme))
                }
                .tint(PitchTheme.indigo)
            }
        }
    }

    private var meterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimeSignature.all) { sig in
                    let locked = sig.requiresPro && !isPro
                    Button {
                        if locked { showPaywall = true } else { metronome.timeSignature = sig }
                    } label: {
                        HStack(spacing: 4) {
                            Text(sig.label)
                            if locked { ProBadge() }
                        }
                        .pitchChip(selected: metronome.timeSignature == sig)
                    }
                    .accessibilityLabel("Time signature \(sig.label)\(locked ? ", Pro" : "")")
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var subdivisionPicker: some View {
        HStack(spacing: 8) {
            ForEach(Subdivision.allCases) { sub in
                let locked = sub.requiresPro && !isPro
                Button {
                    if locked { showPaywall = true } else { metronome.subdivision = sub }
                } label: {
                    VStack(spacing: 2) {
                        Text(sub.symbol).font(.title3)
                        HStack(spacing: 3) {
                            Text(sub.label).font(.caption2)
                            if locked { Image(systemName: "lock.fill").font(.system(size: 8)) }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .pitchChip(selected: metronome.subdivision == sub)
                }
                .accessibilityLabel("\(sub.label) subdivision\(locked ? ", Pro" : "")")
            }
        }
    }

    // MARK: - Presets card

    private var presetsCard: some View {
        PitchCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    PitchSectionHeader(title: "Presets", systemImage: "square.stack.3d.up")
                    Spacer()
                    Button {
                        if !isPro && presets.count >= ProInfo.freePresetLimit {
                            showPaywall = true
                        } else {
                            presetName = "\(metronome.bpm) BPM"
                            showSavePreset = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill").font(.title3)
                            .foregroundStyle(PitchTheme.indigo)
                    }
                    .accessibilityLabel("Save current as preset")
                }

                if presets.isEmpty {
                    Text("No presets yet. Save your current tempo to recall it instantly.")
                        .font(.subheadline)
                        .foregroundStyle(PitchTheme.secondaryText(scheme))
                } else {
                    ForEach(presets) { preset in
                        presetRow(preset)
                    }
                }
                if !isPro {
                    Text("Free tier saves up to \(ProInfo.freePresetLimit) presets.")
                        .font(.caption)
                        .foregroundStyle(PitchTheme.secondaryText(scheme))
                }
            }
        }
    }

    private func presetRow(_ preset: MetronomePreset) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(preset.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PitchTheme.primaryText(scheme))
                Text("\(preset.bpm) BPM · \(preset.timeSignature.label) · \(preset.subdivision.label)")
                    .font(.caption)
                    .foregroundStyle(PitchTheme.secondaryText(scheme))
            }
            Spacer()
            Button("Load") { metronome.apply(preset) }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PitchTheme.indigo)
            Button(role: .destructive) {
                modelContext.delete(preset)
                try? modelContext.save()
            } label: {
                Image(systemName: "trash")
            }
            .foregroundStyle(PitchTheme.offTune)
            .accessibilityLabel("Delete preset \(preset.name)")
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Practice chart card

    private var practiceCard: some View {
        PitchCard {
            VStack(alignment: .leading, spacing: 12) {
                PitchSectionHeader(title: "Practice this week", systemImage: "chart.bar.fill")
                PracticeChart()
            }
        }
    }

    // MARK: - Actions

    private func adjustBPM(_ delta: Int) {
        metronome.bpm = min(max(metronome.bpm + delta, MetronomeEngine.minBPM), MetronomeEngine.maxBPM)
    }

    private func tap() {
        metronome.tapTempo()
        Haptics.tap(hapticOnBeat)
    }

    private func toggleTransport() {
        if metronome.isPlaying {
            stopAndLog()
        } else {
            practiceStart = .now
            metronome.start()
        }
    }

    /// Stop and log the elapsed session minutes for the practice chart.
    private func stopAndLog() {
        guard metronome.isPlaying else { return }
        let bpm = metronome.bpm
        metronome.stop()
        if let start = practiceStart {
            let minutes = Date().timeIntervalSince(start) / 60.0
            if minutes >= 0.25 {
                modelContext.insert(PracticeLog(date: .now, minutes: minutes, bpm: bpm))
                try? modelContext.save()
            }
        }
        practiceStart = nil
    }

    private func savePreset() {
        let trimmed = presetName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "\(metronome.bpm) BPM" : trimmed
        let preset = MetronomePreset(name: name,
                                     bpm: metronome.bpm,
                                     timeSigTop: metronome.timeSignature.top,
                                     timeSigBottom: metronome.timeSignature.bottom,
                                     subdivision: metronome.subdivision,
                                     accentFirst: metronome.accentFirst)
        modelContext.insert(preset)
        try? modelContext.save()
        presetName = ""
        Haptics.success(hapticOnBeat)
    }
}
