import SwiftUI
import SwiftData

struct ReferenceView: View {
    @EnvironmentObject private var tone: ToneEngine
    @Query(sort: \CustomTuning.createdAt) private var customTunings: [CustomTuning]
    @AppStorage("selectedTuningId") private var selectedTuningId = "guitar-standard"
    @AppStorage("a4") private var a4 = 440.0
    @AppStorage("useFlats") private var useFlats = false

    private var pipeNotes: [String] {
        let notes: [String]
        if selectedTuningId.hasPrefix("custom-") {
            let id = String(selectedTuningId.dropFirst("custom-".count))
            notes = customTunings.first { $0.id.uuidString == id }?.noteNames ?? []
        } else {
            notes = TuningPreset.all.first { $0.id == selectedTuningId }?.notes ?? []
        }
        return notes.isEmpty ? ["C4", "D4", "E4", "F4", "G4", "A4", "B4"] : notes
    }

    private let tableOctaves = [2, 3, 4, 5]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        pitchPipeCard
                        tableCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Pitches")
            .onDisappear { tone.stopTone() }
        }
    }

    private var pitchPipeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Pitch pipe")
            Text("Tap a note to hold a reference tone.")
                .font(.subheadline).foregroundStyle(Brand.text2)
            let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(pipeNotes, id: \.self) { note in
                    pipeButton(note)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func pipeButton(_ note: String) -> some View {
        let isPlaying = tone.playingNote == note
        return Button {
            if let freq = TunerEngine.frequency(forName: note, a4: a4) {
                tone.toggleTone(frequency: freq, note: note)
                Haptics.tap()
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: isPlaying ? "speaker.wave.2.fill" : "speaker.fill")
                    .font(.caption)
                Text(note).font(Brand.mono(16, weight: .semibold))
            }
            .foregroundStyle(isPlaying ? .white : Brand.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isPlaying ? AnyShapeStyle(Brand.magic) : AnyShapeStyle(.ultraThinMaterial),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Brand.glassStroke.opacity(0.4), lineWidth: 1))
        }
        .accessibilityLabel("\(note) reference tone")
        .accessibilityAddTraits(isPlaying ? .isSelected : [])
    }

    private var tableCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Eyebrow(text: "Note frequencies")
                Spacer()
                Text("A4 = \(Int(a4)) Hz").font(Brand.mono(11)).foregroundStyle(Brand.text3)
            }
            let names = useFlats ? TunerEngine.flatNames : TunerEngine.sharpNames
            ForEach(0..<12, id: \.self) { semitone in
                HStack(spacing: 8) {
                    Text(names[semitone]).font(Brand.mono(14, weight: .semibold))
                        .foregroundStyle(Brand.text).frame(width: 36, alignment: .leading)
                    ForEach(tableOctaves, id: \.self) { octave in
                        let midi = (octave + 1) * 12 + semitone
                        let freq = TunerEngine.frequency(forMidi: midi, a4: a4)
                        Button {
                            tone.toggleTone(frequency: freq, note: "\(names[semitone])\(octave)")
                            Haptics.tap()
                        } label: {
                            Text(String(format: "%.1f", freq))
                                .font(Brand.mono(11))
                                .foregroundStyle(tone.playingNote == "\(names[semitone])\(octave)" ? Brand.magic : Brand.text2)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                        }
                        .accessibilityLabel("\(names[semitone]) octave \(octave), \(Int(freq)) hertz")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}
