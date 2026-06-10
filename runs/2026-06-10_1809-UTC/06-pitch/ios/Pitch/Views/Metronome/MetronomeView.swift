import SwiftUI
import SwiftData

struct MetronomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MetronomePreset.createdAt) private var presets: [MetronomePreset]

    @State private var metronome = Metronome()
    @State private var tapTimes: [Date] = []
    @State private var showSave = false
    @State private var newPresetName = ""
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 22) {
                        beatDots
                        bpmDisplay
                        bpmControls
                        signatureControls
                        actionRow
                        presetsSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Metronome")
            .alert("Save preset", isPresented: $showSave) {
                TextField("Name", text: $newPresetName)
                Button("Save") { savePreset() }.disabled(newPresetName.trimmingCharacters(in: .whitespaces).isEmpty)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Save \(metronome.bpm) BPM, \(metronome.beatsPerBar)/4.")
            }
        }
        .onDisappear { metronome.stop() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { metronome.stop() } }
    }

    private var beatDots: some View {
        HStack(spacing: 12) {
            ForEach(0..<metronome.beatsPerBar, id: \.self) { i in
                Circle()
                    .fill(dotColor(i))
                    .frame(width: i == 0 ? 22 : 18, height: i == 0 ? 22 : 18)
                    .scaleEffect(metronome.isRunning && metronome.currentBeat == i && !reduceMotion ? 1.4 : 1)
                    .animation(.easeOut(duration: 0.1), value: metronome.currentBeat)
            }
        }
        .frame(height: 40)
        .accessibilityLabel("\(metronome.beatsPerBar) beats per bar")
    }

    private func dotColor(_ i: Int) -> Color {
        if metronome.isRunning && metronome.currentBeat == i {
            return i == 0 ? Brand.magic : Brand.dynamic(0x5E7F9E, 0x8FAEE8)
        }
        return i == 0 ? Brand.text2 : Brand.text3.opacity(0.5)
    }

    private var bpmDisplay: some View {
        VStack(spacing: 2) {
            Text("\(metronome.bpm)")
                .font(.system(size: 76, weight: .bold, design: .rounded))
                .foregroundStyle(Brand.text)
                .contentTransition(.numericText())
            Text("BPM · \(currentMarking)")
                .font(.subheadline).foregroundStyle(Brand.text2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metronome.bpm) beats per minute, \(currentMarking)")
    }

    private var currentMarking: String {
        switch metronome.bpm {
        case ..<60: "Largo"; case 60..<76: "Adagio"; case 76..<108: "Andante"
        case 108..<120: "Moderato"; case 120..<156: "Allegro"; case 156..<176: "Vivace"; default: "Presto"
        }
    }

    private var bpmControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                stepButton("-5") { changeBPM(-5) }
                stepButton("-1") { changeBPM(-1) }
                stepButton("+1") { changeBPM(1) }
                stepButton("+5") { changeBPM(5) }
            }
            Slider(value: Binding(
                get: { Double(metronome.bpm) },
                set: { metronome.setTempo(Int($0)) }), in: 40...240, step: 1)
                .tint(Brand.dynamic(0x5E7F9E, 0x8FAEE8))
                .accessibilityValue("\(metronome.bpm) BPM")
        }
    }

    private func stepButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                .foregroundStyle(Brand.text)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Change tempo by \(label)")
    }

    private var signatureControls: some View {
        HStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("BEATS").font(Brand.mono(11, weight: .medium)).tracking(1.2).foregroundStyle(Brand.text3)
                Stepper("\(metronome.beatsPerBar)", value: Binding(
                    get: { metronome.beatsPerBar },
                    set: { metronome.beatsPerBar = max(1, min(12, $0)) }), in: 1...12)
                    .labelsHidden()
                Text("\(metronome.beatsPerBar) / 4").font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
            }
            Toggle(isOn: $metronome.accentFirst) {
                Text("Accent beat 1").font(.subheadline)
            }
            .tint(Brand.live)
        }
        .padding(16).glassCard(padding: 0).padding(.horizontal, 0)
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button { metronome.toggle(); Haptics.tap() } label: {
                Label(metronome.isRunning ? "Stop" : "Start",
                      systemImage: metronome.isRunning ? "stop.fill" : "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(InkButtonStyle())

            Button { tap() } label: {
                Label("Tap", systemImage: "hand.tap").frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyle())

            Button { showSave = true; newPresetName = "" } label: {
                Image(systemName: "square.and.arrow.down").frame(width: 44)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Save preset")
        }
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PRESETS").font(Brand.mono(12, weight: .medium)).tracking(1.4).foregroundStyle(Brand.text3)
            if presets.isEmpty {
                Text("Save a tempo to keep it here.").font(.subheadline).foregroundStyle(Brand.text3)
            } else {
                ForEach(presets) { p in
                    HStack {
                        Button { load(p) } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(p.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                    Text("\(p.bpm) BPM · \(p.beatsPerBar)/4 · \(p.marking)")
                                        .font(.caption).foregroundStyle(Brand.text2)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.left.circle").foregroundStyle(Brand.dynamic(0x5E7F9E, 0x8FAEE8))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12).glassCard(padding: 0)
                    .swipeActions {
                        Button(role: .destructive) {
                            context.delete(p); try? context.save(); Haptics.warning()
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                    .accessibilityLabel("Preset \(p.name), \(p.bpm) BPM. Double tap to load.")
                }
            }
        }
    }

    private func changeBPM(_ delta: Int) {
        metronome.setTempo(metronome.bpm + delta)
        Haptics.selection()
    }

    private func tap() {
        let now = Date()
        tapTimes.append(now)
        tapTimes = tapTimes.filter { now.timeIntervalSince($0) < 3 }
        if tapTimes.count >= 2 {
            let intervals = zip(tapTimes.dropFirst(), tapTimes).map { $0.timeIntervalSince($1) }
            if let bpm = Metronome.bpm(fromIntervals: intervals) {
                metronome.setTempo(bpm)
            }
        }
        Haptics.tap()
    }

    private func load(_ p: MetronomePreset) {
        metronome.setTempo(p.bpm)
        metronome.beatsPerBar = p.beatsPerBar
        metronome.accentFirst = p.accentFirst
        Haptics.selection()
    }

    private func savePreset() {
        let name = newPresetName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        context.insert(MetronomePreset(name: name, bpm: metronome.bpm,
                                       beatsPerBar: metronome.beatsPerBar, accentFirst: metronome.accentFirst))
        try? context.save()
        Haptics.success()
    }
}

#Preview {
    MetronomeView().modelContainer(for: [Tuning.self, MetronomePreset.self], inMemory: true)
}
