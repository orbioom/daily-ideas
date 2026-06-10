import SwiftUI
import SwiftData

struct MetronomeView: View {
    @EnvironmentObject private var metronome: MetronomeController
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \MetronomePreset.createdAt, order: .reverse) private var presets: [MetronomePreset]
    @State private var showSavePreset = false
    @State private var presetName = ""

    private let subdivisionLabels = [1: "Quarter", 2: "Eighths", 3: "Triplets", 4: "Sixteenths"]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 18) {
                        beatRow
                        bpmCard
                        signatureCard
                        startButton
                        if !presets.isEmpty { presetsCard }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Metronome")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { presetName = ""; showSavePreset = true } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .accessibilityLabel("Save preset")
                }
            }
            .onDisappear { metronome.stop() }
            .alert("Save preset", isPresented: $showSavePreset) {
                TextField("Name", text: $presetName)
                Button("Save") { savePreset() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var beatRow: some View {
        HStack(spacing: 10) {
            ForEach(0..<max(1, metronome.beatsPerBar), id: \.self) { i in
                Circle()
                    .fill(beatColor(i))
                    .frame(width: i == 0 ? 22 : 18, height: i == 0 ? 22 : 18)
                    .scaleEffect(metronome.currentBeat == i && !reduceMotion ? 1.3 : 1)
                    .animation(Brand.ease(0.15), value: metronome.currentBeat)
            }
        }
        .frame(height: 40)
        .accessibilityHidden(true)
    }

    private func beatColor(_ i: Int) -> Color {
        if metronome.currentBeat == i { return i == 0 ? Brand.magic : Brand.live }
        return Brand.text3.opacity(0.3)
    }

    private var bpmCard: some View {
        VStack(spacing: 14) {
            Text("\(metronome.bpm)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(Brand.text)
                .contentTransition(.numericText())
                .animation(Brand.ease(0.2), value: metronome.bpm)
            Text("BPM · \(tempoTerm(metronome.bpm))")
                .font(Brand.mono(12)).foregroundStyle(Brand.text3)

            HStack(spacing: 16) {
                Button { metronome.bpm = max(20, metronome.bpm - 1) } label: {
                    Image(systemName: "minus").frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("Decrease tempo")
                Slider(value: Binding(get: { Double(metronome.bpm) },
                                      set: { metronome.bpm = Int($0) }), in: 20...300, step: 1)
                    .tint(Brand.text)
                Button { metronome.bpm = min(300, metronome.bpm + 1) } label: {
                    Image(systemName: "plus").frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("Increase tempo")
            }
            .foregroundStyle(Brand.text)

            Button { metronome.tap(); Haptics.tap() } label: {
                Label("Tap tempo", systemImage: "hand.tap.fill")
            }
            .buttonStyle(GlassButtonStyle())
        }
        .glassCard()
        .accessibilityElement(children: .contain)
    }

    private var signatureCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Beats per bar").foregroundStyle(Brand.text)
                Spacer()
                Picker("Beats", selection: $metronome.beatsPerBar) {
                    ForEach(2...8, id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.menu).tint(Brand.text)
            }
            Divider().background(Brand.hairline)
            HStack {
                Text("Subdivision").foregroundStyle(Brand.text)
                Spacer()
                Picker("Subdivision", selection: $metronome.subdivision) {
                    ForEach([1, 2, 3, 4], id: \.self) { Text(subdivisionLabels[$0] ?? "\($0)").tag($0) }
                }
                .pickerStyle(.menu).tint(Brand.text)
            }
            Divider().background(Brand.hairline)
            Toggle("Accent first beat", isOn: $metronome.accentFirst)
        }
        .glassCard()
    }

    private var startButton: some View {
        Button {
            metronome.toggle(); Haptics.tap()
        } label: {
            Label(metronome.isRunning ? "Stop" : "Start",
                  systemImage: metronome.isRunning ? "stop.fill" : "play.fill")
        }
        .buttonStyle(InkButtonStyle())
    }

    private var presetsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Presets")
            ForEach(presets) { preset in
                Button { apply(preset) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.name).font(.headline).foregroundStyle(Brand.text)
                            Text("\(preset.bpm) BPM · \(preset.beatsPerBar)/4")
                                .font(Brand.mono(12)).foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.left.circle").foregroundStyle(Brand.text3)
                    }
                    .glassCard(padding: 14)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        context.delete(preset); try? context.save()
                    } label: { Label("Delete", systemImage: "trash") }
                }
            }
        }
    }

    private func apply(_ preset: MetronomePreset) {
        metronome.bpm = preset.bpm
        metronome.beatsPerBar = preset.beatsPerBar
        metronome.subdivision = preset.subdivision
        metronome.accentFirst = preset.accentFirst
        Haptics.selection()
    }

    private func savePreset() {
        let trimmed = presetName.trimmingCharacters(in: .whitespaces)
        let finalName = trimmed.isEmpty ? "\(metronome.bpm) BPM" : trimmed
        context.insert(MetronomePreset(name: finalName, bpm: metronome.bpm,
                                       beatsPerBar: metronome.beatsPerBar,
                                       subdivision: metronome.subdivision,
                                       accentFirst: metronome.accentFirst))
        try? context.save()
        Haptics.success()
    }

    private func tempoTerm(_ bpm: Int) -> String {
        switch bpm {
        case ..<60: return "Largo"
        case 60..<76: return "Adagio"
        case 76..<108: return "Andante"
        case 108..<120: return "Moderato"
        case 120..<156: return "Allegro"
        case 156..<176: return "Vivace"
        default: return "Presto"
        }
    }
}
