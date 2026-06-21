import SwiftUI
import SwiftData

struct RungPracticeView: View {
    @Query private var prefs: [RungPrefs]
    @Environment(\.modelContext) private var ctx
    @State private var engine = RungEngine()
    @State private var input = ""
    @State private var isStarted = false

    private var pref: RungPrefs? { prefs.first }

    var body: some View {
        NavigationStack {
            if !isStarted {
                startScreen
            } else {
                VStack(spacing: 0) {
                    puzzleHeader.padding()
                    ladderList.padding(.horizontal)
                    Spacer()
                    if engine.isSolved {
                        solvedBanner.padding()
                        Button("New Puzzle") { newGame() }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                    } else {
                        inputArea.padding()
                    }
                }
                .navigationTitle("Practice")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Skip") { newGame() }.foregroundStyle(.green)
                    }
                }
                .onChange(of: engine.isSolved) { _, solved in
                    if solved { saveResult() }
                }
            }
        }
    }

    private var startScreen: some View {
        VStack(spacing: 24) {
            Image(systemName: "shuffle")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("Practice Mode")
                .font(.title.weight(.bold))
            Text("Random word ladder puzzles with no time pressure. Perfect for sharpening your skills!")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Button("Start Puzzle") { newGame() }
                .buttonStyle(.borderedProminent)
                .tint(.green)
        }
        .navigationTitle("Practice")
    }

    private var puzzleHeader: some View {
        HStack {
            VStack(spacing: 2) {
                Text("START").font(.caption2).foregroundStyle(.secondary)
                Text(engine.startWord.uppercased())
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundStyle(.green)
            }
            Spacer()
            Text("\(engine.chain.count - 1) steps")
                .font(.callout.weight(.semibold))
            Spacer()
            VStack(spacing: 2) {
                Text("TARGET").font(.caption2).foregroundStyle(.secondary)
                Text(engine.targetWord.uppercased())
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var ladderList: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(engine.chain.enumerated()), id: \.offset) { idx, word in
                    HStack(spacing: 6) {
                        ForEach(Array(word.enumerated()), id: \.offset) { ci, ch in
                            let changed = idx > 0 && Array(engine.chain[idx - 1])[ci] != ch
                            Text(String(ch).uppercased())
                                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                .frame(width: 40, height: 40)
                                .background(changed ? Color.green.opacity(0.2) : Color(.systemGray6))
                                .foregroundStyle(changed ? .green : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        Spacer()
                        if idx == engine.chain.count - 1 && idx > 0 && !engine.isSolved {
                            Button(action: engine.undo) {
                                Image(systemName: "arrow.uturn.backward").foregroundStyle(.red).font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 320)
    }

    private var inputArea: some View {
        VStack(spacing: 8) {
            if !engine.errorMessage.isEmpty {
                Text(engine.errorMessage).font(.caption).foregroundStyle(.red)
            }
            HStack(spacing: 10) {
                TextField("Next word…", text: $input)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onSubmit { doSubmit() }
                Button(action: doSubmit) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2).foregroundStyle(.green)
                }
            }
            HStack {
                Button(action: { engine.requestHint(maxHints: pref?.showHintCount ?? 3) }) {
                    Label("Hint (\(engine.hintsUsed)/\(pref?.showHintCount ?? 3))",
                          systemImage: "lightbulb")
                        .font(.caption).foregroundStyle(.orange)
                }
                .disabled(engine.isComputing)
                if !engine.hint.isEmpty {
                    Text(engine.hint).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }

    private var solvedBanner: some View {
        Text("Solved in \(engine.chain.count - 1) steps! 🎉")
            .font(.headline).foregroundStyle(.green)
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func newGame() {
        engine.startRandom()
        isStarted = true
        input = ""
    }

    private func doSubmit() {
        engine.submit(word: input)
        if engine.errorMessage.isEmpty { input = "" }
    }

    private func saveResult() {
        let r = RungResult(
            mode: "practice",
            startWord: engine.startWord,
            targetWord: engine.targetWord,
            steps: engine.chain.count - 1,
            parSteps: engine.parSteps,
            solved: true,
            durationSeconds: engine.elapsedSeconds
        )
        ctx.insert(r)
    }
}
