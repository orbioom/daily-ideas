import SwiftUI

/// Memory mission: watch a sequence of tiles light up, then tap them back in order. Get it
/// wrong and the same sequence replays. Each correct full sequence counts as one rep.
struct MemoryMissionView: View {
    let difficulty: MissionDifficulty
    let reps: Int
    let onComplete: () -> Void
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var rng = SplitMix64(seed: 1)
    @State private var sequence: [Int] = []
    @State private var lit: Int? = nil
    @State private var inputIndex = 0
    @State private var done = 0
    @State private var phase: Phase = .idle
    @State private var wrongFlash = false

    private enum Phase { case idle, showing, input }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    private let tileColors: [Color] = [
        Color(hex: 0xFF8275), Color(hex: 0x5BD3A6),
        Color(hex: 0xF0B45F), Color(hex: 0x8AB4FF)
    ]

    init(difficulty: MissionDifficulty, reps: Int, onComplete: @escaping () -> Void) {
        self.difficulty = difficulty
        self.reps = max(1, reps)
        self.onComplete = onComplete
    }

    var body: some View {
        MissionShell(title: "Repeat the pattern",
                     subtitle: phase == .showing ? "Watch closely…" : "Now tap them in order.",
                     repsTotal: reps, repsDone: done) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<MissionEngine.memoryTileCount, id: \.self) { i in
                    tile(i)
                }
            }
            .frame(maxWidth: 260)
        }
        .task { startRound() }
    }

    private func tile(_ i: Int) -> some View {
        let isLit = lit == i
        return RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(tileColors[i % tileColors.count].opacity(isLit ? 1 : 0.35))
            .frame(height: 92)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            )
            .scaleEffect(isLit && !reduceMotion ? 1.06 : 1)
            .overlay(wrongFlash ? RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.1)) : nil)
            .contentShape(Rectangle())
            .onTapGesture { tap(i) }
            .accessibilityLabel("Tile \(i + 1)")
            .accessibilityAddTraits(.isButton)
    }

    // MARK: Flow

    private func startRound() {
        if sequence.isEmpty {
            var seed = SplitMix64(seed: UInt64(Date().timeIntervalSince1970.bitPattern) ^ 0x0E0E0E0E)
            sequence = MissionEngine.makeMemorySequence(difficulty: difficulty, rng: &seed)
            rng = seed
        }
        playSequence()
    }

    private func playSequence() {
        phase = .showing
        inputIndex = 0
        lit = nil
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            for tileIndex in sequence {
                lit = tileIndex
                Haptics.tap(settings.hapticsEnabled)
                try? await Task.sleep(nanoseconds: 480_000_000)
                lit = nil
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            phase = .input
        }
    }

    private func tap(_ i: Int) {
        guard phase == .input else { return }
        guard inputIndex < sequence.count else { return }
        if sequence[inputIndex] == i {
            Haptics.select(settings.hapticsEnabled)
            lit = i
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { if phase == .input { lit = nil } }
            inputIndex += 1
            if inputIndex >= sequence.count {
                done += 1
                if done >= reps {
                    onComplete()
                } else {
                    // New sequence for the next rep.
                    sequence = []
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { startRound() }
                }
            }
        } else {
            // Wrong — flash and replay.
            Haptics.warning(settings.hapticsEnabled)
            wrongFlash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                wrongFlash = false
                playSequence()
            }
        }
    }
}
