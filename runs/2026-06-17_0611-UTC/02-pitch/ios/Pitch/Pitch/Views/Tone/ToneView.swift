import SwiftUI

/// Reference-pitch pipe: pick a note and play a sustained sine. Quick chromatic
/// buttons for a chosen octave. Full range is Pro; free tier is limited to a
/// central octave window.
struct ToneView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(ToneGenerator.self) private var tone

    @AppStorage("a4Reference") private var a4Reference: Double = NoteMath.defaultA4
    @AppStorage("isPro") private var isPro: Bool = false

    @State private var octave: Int = 4
    @State private var showPaywall = false

    // Free tier: octaves 3–5. Pro: full 1–6.
    private var octaveRange: ClosedRange<Int> { isPro ? 1...6 : 3...5 }

    var body: some View {
        NavigationStack {
            ZStack {
                PitchTheme.appBackground(scheme).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        nowPlayingCard
                        octavePicker
                        noteGrid
                        if !isPro {
                            unlockHint
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Tone")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
        .onDisappear { tone.stop() }
    }

    private var nowPlayingCard: some View {
        PitchCard {
            VStack(spacing: 8) {
                Image(systemName: "waveform")
                    .font(.system(size: 34))
                    .foregroundStyle(tone.isPlaying ? PitchTheme.indigo : PitchTheme.secondaryText(scheme))
                    .symbolEffect(.variableColor, isActive: tone.isPlaying)
                    .accessibilityHidden(true)
                if let midi = tone.playingMidi,
                   let r = NoteMath.reading(forFrequency: NoteMath.frequency(forMidi: midi, a4: a4Reference), a4: a4Reference) {
                    Text(r.label)
                        .font(PitchTheme.display(40))
                        .foregroundStyle(PitchTheme.primaryText(scheme))
                    Text(String(format: "%.1f Hz", r.targetFrequency))
                        .font(PitchTheme.mono(15))
                        .foregroundStyle(PitchTheme.secondaryText(scheme))
                } else {
                    Text("Pick a note")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(PitchTheme.secondaryText(scheme))
                }
                Text("A4 = \(Int(a4Reference)) Hz")
                    .font(.caption)
                    .foregroundStyle(PitchTheme.secondaryText(scheme))
                if tone.isPlaying {
                    Button("Stop") { tone.stop() }
                        .buttonStyle(PitchSecondaryButtonStyle())
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }
    }

    private var octavePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            PitchSectionHeader(title: "Octave", systemImage: "arrow.up.arrow.down")
            Picker("Octave", selection: $octave) {
                ForEach(Array(octaveRange), id: \.self) { o in
                    Text("\(o)").tag(o)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: octaveRange.contains(octave)) { _, valid in
                if !valid { octave = max(octaveRange.lowerBound, min(octave, octaveRange.upperBound)) }
            }
        }
    }

    private var noteGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
            ForEach(NoteMath.noteNames, id: \.self) { note in
                noteButton(note)
            }
        }
    }

    private func noteButton(_ note: String) -> some View {
        let midi = NoteMath.midi(forName: note, octave: octave)
        let isActive = midi != nil && tone.playingMidi == midi
        return Button {
            guard let midi else { return }
            tone.toggle(midi: midi, a4: a4Reference)
        } label: {
            Text(note)
                .font(PitchTheme.display(20))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(isActive ? Color.white : PitchTheme.primaryText(scheme))
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isActive ? PitchTheme.indigo : PitchTheme.subtleSurface(scheme))
                )
        }
        .accessibilityLabel("\(note)\(octave)")
        .accessibilityValue(isActive ? "Playing" : "")
        .accessibilityHint("Plays a reference tone")
    }

    private var unlockHint: some View {
        Button { showPaywall = true } label: {
            HStack {
                Image(systemName: "lock.fill")
                Text("Unlock the full chromatic range with Pro")
                    .font(.subheadline.weight(.medium))
                Spacer()
                ProBadge()
            }
            .foregroundStyle(PitchTheme.indigo)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(PitchTheme.indigo.opacity(0.12))
            )
        }
    }
}
