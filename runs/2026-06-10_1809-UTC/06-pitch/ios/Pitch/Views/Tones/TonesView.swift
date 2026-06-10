import SwiftUI
import SwiftData

struct TonesView: View {
    @Query private var tunings: [Tuning]
    @AppStorage("a4") private var a4 = 440
    @AppStorage("selectedTuningID") private var selectedTuningID = ""

    @State private var generator = ToneGenerator()
    @State private var chromaticOctave = 4
    @Environment(\.scenePhase) private var scenePhase

    private var selectedTuning: Tuning? {
        tunings.first { $0.id.uuidString == selectedTuningID } ?? tunings.first { $0.isBuiltIn }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 20) {
                        if generator.isPlaying { nowPlaying }
                        stringsCard
                        chromaticCard
                        NavigationLink {
                            TuningsManagerView()
                        } label: {
                            Label("Manage tunings", systemImage: "slider.horizontal.3")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Reference")
        }
        .onDisappear { generator.stop() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { generator.stop() } }
    }

    private var nowPlaying: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.wave.3.fill").foregroundStyle(Brand.live)
                .symbolEffect(.variableColor, isActive: true)
            Text("Playing \(generator.playingLabel ?? "")")
                .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
            Spacer()
            Button { generator.stop() } label: {
                Image(systemName: "stop.circle.fill").font(.title3).foregroundStyle(Brand.danger)
            }
            .accessibilityLabel("Stop tone")
        }
        .padding(14)
        .background(Brand.live.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }

    private var stringsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedTuning.map { "\($0.instrument.title) · \($0.name)" } ?? "Tuning")
                    .font(.headline).foregroundStyle(Brand.text)
                Spacer()
                tuningMenu
            }
            Text("Tap a string to hear its reference pitch at A4 = \(a4) Hz.")
                .font(.caption).foregroundStyle(Brand.text2)
            if let tuning = selectedTuning {
                let cols = [GridItem(.adaptive(minimum: 70), spacing: 10)]
                LazyVGrid(columns: cols, spacing: 10) {
                    ForEach(Array(tuning.notes.enumerated()), id: \.offset) { _, note in
                        toneButton(label: note, frequency: NoteMath.frequency(forName: note, a4: Double(a4)))
                    }
                }
            }
        }
        .padding(18).glassCard()
    }

    private var tuningMenu: some View {
        Menu {
            ForEach(Instrument.allCases) { inst in
                let group = tunings.filter { $0.instrument == inst }
                if !group.isEmpty {
                    Section(inst.title) {
                        ForEach(group) { t in
                            Button {
                                selectedTuningID = t.id.uuidString
                                generator.stop()
                            } label: { Text("\(t.name) · \(t.notes.joined(separator: " "))") }
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.left.arrow.right.circle").foregroundStyle(Brand.dynamic(0x5E7F9E, 0x8FAEE8))
        }
        .accessibilityLabel("Change tuning")
    }

    private var chromaticCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Chromatic").font(.headline).foregroundStyle(Brand.text)
                Spacer()
                Stepper("Octave \(chromaticOctave)", value: $chromaticOctave, in: 1...7)
                    .labelsHidden()
                Text("Oct \(chromaticOctave)").font(Brand.mono(13, weight: .medium)).foregroundStyle(Brand.text2)
            }
            let cols = [GridItem(.adaptive(minimum: 64), spacing: 8)]
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(Array(NoteMath.asciiNames.enumerated()), id: \.offset) { idx, name in
                    let display = NoteMath.names[idx]
                    let label = "\(display)\(chromaticOctave)"
                    let midi = (chromaticOctave + 1) * 12 + idx
                    toneButton(label: label, frequency: NoteMath.frequency(midi: midi, a4: Double(a4)))
                }
            }
        }
        .padding(18).glassCard()
    }

    private func toneButton(label: String, frequency: Double?) -> some View {
        let isPlaying = generator.isPlaying && generator.playingLabel == label
        return Button {
            if let f = frequency { generator.toggle(frequency: f, label: label); Haptics.tap() }
        } label: {
            VStack(spacing: 2) {
                Text(label).font(Brand.mono(16, weight: .semibold))
                if isPlaying { Image(systemName: "waveform").font(.caption2) }
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .foregroundStyle(isPlaying ? .white : Brand.text)
            .background(isPlaying ? AnyShapeStyle(Brand.live) : AnyShapeStyle(.ultraThinMaterial),
                        in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(frequency == nil)
        .accessibilityLabel("\(label)\(isPlaying ? ", playing" : "")")
    }
}

#Preview {
    TonesView().modelContainer(for: [Tuning.self, MetronomePreset.self], inMemory: true)
}
