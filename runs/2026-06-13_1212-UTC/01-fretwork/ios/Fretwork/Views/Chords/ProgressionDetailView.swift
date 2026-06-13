import SwiftUI

/// Shows a progression as a row of chord boxes plus a simple auto-advancing
/// "play-along" highlighter so a learner can strum in time.
struct ProgressionDetailView: View {
    let prog: Progression
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var playing = false
    @State private var current = 0
    @State private var bpm: Double = 70
    @State private var timer: Timer?

    private var chords: [Chord] { prog.chords() }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    Card {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(prog.numerals).font(Theme.serif(22, .bold)).foregroundStyle(Theme.accent)
                            Text(prog.feel).font(Theme.rounded(15, .regular)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .padding(.horizontal, 16)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 14)], spacing: 14) {
                        ForEach(Array(chords.enumerated()), id: \.offset) { idx, chord in
                            VStack(spacing: 6) {
                                Text(chord.symbol).font(Theme.serif(18, .bold)).foregroundStyle(Theme.ink)
                                ChordDiagram(chord: chord, showFingers: false).frame(height: 110)
                            }
                            .padding(10)
                            .background((playing && idx == current) ? Theme.accentSoft : Theme.surface,
                                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke((playing && idx == current) ? Theme.accent : Theme.hairline,
                                        lineWidth: (playing && idx == current) ? 2 : 1))
                            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: current)
                        }
                    }
                    .padding(.horizontal, 16)

                    Card {
                        VStack(spacing: 14) {
                            HStack {
                                Text("Tempo").font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                                Spacer()
                                Text("\(Int(bpm)) BPM").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.accent)
                            }
                            Slider(value: $bpm, in: 40...160, step: 5)
                                .tint(Theme.accent)
                                .accessibilityValue("\(Int(bpm)) beats per minute")
                            Button {
                                playing ? stop() : play()
                            } label: {
                                Label(playing ? "Stop" : "Play along",
                                      systemImage: playing ? "stop.fill" : "play.fill")
                                    .font(Theme.rounded(17, .bold))
                                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                                    .background(playing ? Theme.bad : Theme.accent,
                                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle(prog.name)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stop() }
        .onChange(of: bpm) { _, _ in if playing { schedule() } }
    }

    private func play() {
        guard !chords.isEmpty else { return }
        playing = true
        current = 0
        Haptics.tap()
        schedule()
    }

    private func schedule() {
        timer?.invalidate()
        let interval = 60.0 / max(40, bpm) * 2   // one chord per two beats
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            guard !chords.isEmpty else { return }
            current = (current + 1) % chords.count
            Haptics.soft()
        }
    }

    private func stop() {
        playing = false
        timer?.invalidate()
        timer = nil
    }
}
