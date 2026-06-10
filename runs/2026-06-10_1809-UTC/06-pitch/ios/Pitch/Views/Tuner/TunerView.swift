import SwiftUI
import SwiftData

struct TunerView: View {
    @Query private var tunings: [Tuning]
    @AppStorage("a4") private var a4 = 440
    @AppStorage("selectedTuningID") private var selectedTuningID = ""

    @State private var engine = TunerEngine()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var selectedTuning: Tuning? {
        tunings.first { $0.id.uuidString == selectedTuningID } ?? tunings.first { $0.isBuiltIn }
    }

    private var inTune: Bool {
        guard engine.reading != nil, engine.hasSignal else { return false }
        return abs(engine.displayCents) < 5
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                switch engine.permission {
                case .granted: tunerContent
                case .denied: deniedState
                case .undetermined: permissionPrompt
                }
            }
            .navigationTitle("Tuner")
        }
        .onAppear {
            engine.a4 = Double(a4)
            if engine.permission == .granted { engine.start() }
        }
        .onDisappear { engine.stop() }
        .onChange(of: a4) { _, v in engine.a4 = Double(v) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && engine.permission == .granted { engine.start() }
            else { engine.stop() }
        }
    }

    private var tunerContent: some View {
        VStack(spacing: 20) {
            tuningPicker
            Spacer()
            gauge
            noteReadout
            Spacer()
            stringTargets
        }
        .padding(20)
    }

    private var tuningPicker: some View {
        Menu {
            ForEach(Instrument.allCases) { inst in
                let group = tunings.filter { $0.instrument == inst }
                if !group.isEmpty {
                    Section(inst.title) {
                        ForEach(group) { t in
                            Button {
                                selectedTuningID = t.id.uuidString; Haptics.selection()
                            } label: {
                                Label("\(t.name) · \(t.notes.joined(separator: " "))",
                                      systemImage: selectedTuningID == t.id.uuidString ? "checkmark" : "")
                            }
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "guitars")
                Text(selectedTuning.map { "\($0.instrument.title) · \($0.name)" } ?? "Chromatic")
                    .font(.subheadline.weight(.medium))
                Image(systemName: "chevron.down").font(.caption2)
            }
            .foregroundStyle(Brand.text)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .accessibilityLabel("Select tuning")
    }

    private var gauge: some View {
        let cents = engine.hasSignal ? engine.displayCents : 0
        let clamped = max(-50, min(50, cents))
        return ZStack {
            // Arc track
            ForEach(-5...5, id: \.self) { i in
                let isCenter = i == 0
                Capsule()
                    .fill(isCenter ? Brand.live : Brand.text3.opacity(0.5))
                    .frame(width: isCenter ? 4 : 2, height: isCenter ? 26 : 16)
                    .offset(y: -96)
                    .rotationEffect(.degrees(Double(i) * 9))
            }
            // Needle
            Capsule()
                .fill(inTune ? Brand.live : Brand.dynamic(0x5E7F9E, 0x8FAEE8))
                .frame(width: 5, height: 104)
                .offset(y: -52)
                .rotationEffect(.degrees(clamped * 0.9))
                .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7), value: clamped)
            Circle()
                .fill(inTune ? Brand.live : Brand.text2)
                .frame(width: 16, height: 16)
        }
        .frame(height: 130)
        .frame(maxWidth: .infinity)
        .accessibilityElement()
        .accessibilityLabel(engine.hasSignal
            ? "\(Int(cents)) cents \(cents > 0 ? "sharp" : "flat")\(inTune ? ", in tune" : "")"
            : "Listening")
    }

    private var noteReadout: some View {
        VStack(spacing: 6) {
            Text(engine.reading?.displayName ?? "—")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(inTune ? Brand.live : Brand.text)
                .contentTransition(.numericText())
            if engine.hasSignal, let r = engine.reading {
                Text(String(format: "%@%.0f cents · %.1f Hz",
                            engine.displayCents >= 0 ? "+" : "", engine.displayCents, r.frequency))
                    .font(Brand.mono(15, weight: .medium))
                    .foregroundStyle(Brand.text2)
                Text(inTune ? "In tune" : (engine.displayCents > 0 ? "Tune down" : "Tune up"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(inTune ? Brand.live : Brand.warn)
            } else {
                Text("Play a note…").font(.subheadline).foregroundStyle(Brand.text3)
            }
        }
    }

    private var stringTargets: some View {
        Group {
            if let tuning = selectedTuning {
                HStack(spacing: 8) {
                    ForEach(Array(tuning.notes.enumerated()), id: \.offset) { _, note in
                        let isNear = isNearestString(note)
                        Text(note)
                            .font(Brand.mono(15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(isNear ? .white : Brand.text2)
                            .background(isNear ? AnyShapeStyle(inTune ? Brand.live : Brand.dynamic(0x5E7F9E, 0x4E6BA8)) : AnyShapeStyle(.ultraThinMaterial),
                                        in: RoundedRectangle(cornerRadius: 10))
                            .accessibilityLabel("String \(note)\(isNear ? ", current" : "")")
                    }
                }
            }
        }
    }

    private func isNearestString(_ note: String) -> Bool {
        guard let r = engine.reading, engine.hasSignal,
              let tuning = selectedTuning else { return false }
        let targets = tuning.notes.compactMap { name -> (String, Int)? in
            guard let m = NoteMath.midi(forName: name) else { return nil }
            return (name, m)
        }
        guard let nearest = targets.min(by: { abs($0.1 - r.midi) < abs($1.1 - r.midi) }) else { return false }
        return nearest.0 == note
    }

    private var permissionPrompt: some View {
        VStack(spacing: 18) {
            Image(systemName: "mic.circle").font(.system(size: 60, weight: .light))
                .foregroundStyle(Brand.dynamic(0x5E7F9E, 0x8FAEE8))
                .accessibilityHidden(true)
            Text("Tune by ear, instantly").font(.title2.bold()).foregroundStyle(Brand.text)
            Text("Pitch listens through your microphone to detect the note you play. Audio is analyzed on-device and never recorded.")
                .font(.subheadline).foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center).padding(.horizontal, 24)
            Button {
                engine.requestPermission { granted in if granted { engine.start() } }
            } label: { Label("Enable microphone", systemImage: "mic.fill") }
            .buttonStyle(InkButtonStyle())
            .padding(.horizontal, 50)
        }
    }

    private var deniedState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash.circle").font(.system(size: 56, weight: .light))
                .foregroundStyle(Brand.danger)
                .accessibilityHidden(true)
            Text("Microphone is off").font(.title3.bold()).foregroundStyle(Brand.text)
            Text("Enable microphone access for Pitch in the Settings app to use the tuner. The metronome and reference tones still work without it.")
                .font(.subheadline).foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center).padding(.horizontal, 24)
            if let url = URL(string: UIApplication.openSettingsURLString) {
                Link(destination: url) {
                    Label("Open Settings", systemImage: "gear").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
                .padding(.horizontal, 50)
            }
        }
    }
}

#Preview {
    TunerView().modelContainer(for: [Tuning.self, MetronomePreset.self], inMemory: true)
}
