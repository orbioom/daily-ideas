import SwiftUI

struct PackPuzzleView: View {
    let entry: WordEntry
    let onComplete: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var engine = MuddleEngine()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                HStack {
                    Text(entry.category.emoji)
                    Text(entry.hint).font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                }
                .padding()

                guessDisplay
                tileGrid
                controlRow

                if engine.state == .solved {
                    solvedBanner
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Pack Puzzle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { engine.load(entry: entry) }
        }
    }

    private var guessDisplay: some View {
        HStack(spacing: 8) {
            ForEach(0..<engine.targetWord.count, id: \.self) { i in
                let filled = i < engine.selectedIndices.count
                Text(filled ? String(engine.currentGuess[engine.currentGuess.index(engine.currentGuess.startIndex, offsetBy: i)]) : "_")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .frame(width: 38, height: 44)
                    .background(filled ? Color.purple.opacity(0.15) : Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(filled ? .purple : .secondary)
            }
        }
    }

    private var tileGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(8, engine.scrambledLetters.count)), spacing: 10) {
            ForEach(engine.scrambledLetters.indices, id: \.self) { i in
                let selected = engine.selectedIndices.contains(i)
                Button { withAnimation(.spring(response: 0.2)) { engine.tap(index: i) } } label: {
                    Text(engine.scrambledLetters[i])
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .frame(width: 48, height: 48)
                        .background(selected ? Color.purple : Color(.systemGray5), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(selected ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var controlRow: some View {
        HStack(spacing: 16) {
            Button { engine.clear() } label: {
                Label("Clear", systemImage: "xmark")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color(.systemGray5), in: Capsule())
            }
            .buttonStyle(.plain)
            Button { engine.shuffle() } label: {
                Label("Shuffle", systemImage: "shuffle")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color(.systemGray5), in: Capsule())
            }
            .buttonStyle(.plain)
            Button { let _ = engine.useHint() } label: {
                Label("Hint", systemImage: "lightbulb")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color.yellow.opacity(0.2), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var solvedBanner: some View {
        VStack(spacing: 12) {
            Text("🎉 \(entry.word)").font(.title.weight(.bold)).foregroundStyle(.purple)
            Button { onComplete(true); dismiss() } label: {
                Text("Next Word")
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(.purple, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
    }
}
