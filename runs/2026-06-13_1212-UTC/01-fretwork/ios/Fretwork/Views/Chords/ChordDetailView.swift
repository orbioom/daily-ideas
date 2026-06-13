import SwiftUI

struct ChordDetailView: View {
    let chord: Chord
    @AppStorage("showFingerNumbers") private var showFingerNumbers = true
    private let tuning = Tuning.standardGuitar

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    ChordDiagram(chord: chord, showFingers: showFingerNumbers)
                        .frame(height: 260)
                        .padding(.horizontal, 60)
                        .padding(.top, 12)

                    HStack {
                        Pill(text: chord.difficulty.rawValue)
                        if chord.isBarre { Pill(text: "Barre", color: Theme.bad) }
                        Pill(text: "\(chord.notes(tuning: tuning).count) notes", color: Theme.good)
                    }

                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Notes", systemImage: "music.note")
                                .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                            HStack(spacing: 8) {
                                ForEach(Array(chord.notes(tuning: tuning).enumerated()), id: \.offset) { _, note in
                                    Text(note)
                                        .font(Theme.serif(16, .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Theme.accent, in: Circle())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("How to play it", systemImage: "hand.point.up.left.fill")
                                .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                            ForEach(fingeringLines, id: \.self) { line in
                                Text(line)
                                    .font(Theme.rounded(14, .regular))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Card {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Tip", systemImage: "lightbulb.fill")
                                .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                            Text(tip)
                                .font(Theme.rounded(14, .regular)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
        }
        .navigationTitle(chord.symbol)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var fingeringLines: [String] {
        let names = ["1st", "2nd", "3rd", "4th", "5th", "6th"]
        let fingerNames = ["", "index", "middle", "ring", "pinky"]
        var out: [String] = []
        // strings high→low for readability (string 1 = highest)
        for j in stride(from: chord.frets.count - 1, through: 0, by: -1) {
            let label = chord.frets.count - j <= names.count ? "\(names[chord.frets.count - 1 - j]) string" : "string"
            let f = chord.frets[j]
            switch f {
            case -1: out.append("• \(label): don't play (muted)")
            case 0:  out.append("• \(label): open")
            default:
                let fg = chord.fingers.indices.contains(j) ? chord.fingers[j] : 0
                let finger = (fg > 0 && fg < fingerNames.count) ? " · \(fingerNames[fg]) finger" : ""
                out.append("• \(label): fret \(f)\(finger)")
            }
        }
        return out
    }

    private var tip: String {
        if chord.isBarre {
            return "Roll your index finger slightly onto its bony side to barre cleanly, and keep your thumb low behind the neck for leverage."
        }
        switch chord.difficulty {
        case .beginner:
            return "Press just behind the fret, not on top of it, and arch your fingers so they don't mute neighbouring strings."
        case .intermediate:
            return "Keep your fingers close to the strings between changes — small movements mean faster, cleaner transitions."
        case .advanced:
            return "Practise this shape in short bursts. Build the muscle memory before worrying about speed."
        }
    }
}
