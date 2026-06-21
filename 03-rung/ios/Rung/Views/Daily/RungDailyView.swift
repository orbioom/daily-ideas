import SwiftUI
import SwiftData

struct RungDailyView: View {
    @Query private var prefs: [RungPrefs]
    @Environment(\.modelContext) private var ctx
    @State private var engine = RungEngine()
    @State private var input = ""
    @State private var savedToday = false
    @FocusState private var fieldFocused: Bool

    private var pref: RungPrefs? { prefs.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                puzzleHeader.padding()
                ladderView.padding(.horizontal)
                Spacer()
                if engine.isSolved {
                    solvedBanner.padding()
                } else {
                    inputRow.padding()
                }
                hintRow.padding(.bottom, 8)
            }
            .navigationTitle("Daily Rung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New") { engine.startDaily(); savedToday = false }
                        .foregroundStyle(.green)
                }
            }
            .onAppear { engine.startDaily() }
            .onChange(of: engine.isSolved) { _, solved in
                if solved && !savedToday { saveResult(); savedToday = true }
            }
        }
    }

    private var puzzleHeader: some View {
        HStack {
            wordBadge(engine.startWord, label: "Start", color: .green)
            Spacer()
            VStack(spacing: 2) {
                Text("Par \(engine.parSteps)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text("\(engine.chain.count - 1) steps")
                    .font(.callout.weight(.semibold))
                Text(timeString(engine.elapsedSeconds))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            wordBadge(engine.targetWord, label: "Target", color: .orange)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func wordBadge(_ word: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(word.uppercased())
                .font(.system(size: 22, weight: .black, design: .monospaced))
                .foregroundStyle(color)
        }
    }

    private var ladderView: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(engine.chain.enumerated()), id: \.offset) { idx, word in
                    ladderRow(word, idx: idx)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 340)
    }

    private func ladderRow(_ word: String, idx: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(word.enumerated()), id: \.offset) { ci, ch in
                let changed = idx > 0 && Array(engine.chain[idx - 1])[ci] != ch
                Text(String(ch).uppercased())
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .frame(width: 44, height: 44)
                    .background(changed ? Color.green.opacity(0.25) : Color(.systemGray6))
                    .foregroundStyle(changed ? .green : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                if ci < 3 { Spacer().frame(width: 6) }
            }
            Spacer()
            if idx == 0 {
                Image(systemName: "flag.fill").foregroundStyle(.green).font(.caption)
            } else if word == engine.targetWord {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            } else if idx == engine.chain.count - 1 {
                Button(action: engine.undo) {
                    Image(systemName: "arrow.uturn.backward").foregroundStyle(.red)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    private var inputRow: some View {
        VStack(spacing: 8) {
            if !engine.errorMessage.isEmpty {
                Text(engine.errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            HStack(spacing: 10) {
                TextField("Next word…", text: $input)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .focused($fieldFocused)
                    .onSubmit { submit() }
                Button(action: submit) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private var hintRow: some View {
        HStack {
            Button(action: { engine.requestHint(maxHints: pref?.showHintCount ?? 3) }) {
                Label("Hint (\(engine.hintsUsed)/\(pref?.showHintCount ?? 3))",
                      systemImage: engine.isComputing ? "ellipsis.circle" : "lightbulb")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            .disabled(engine.isComputing)
            if !engine.hint.isEmpty {
                Text(engine.hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private var solvedBanner: some View {
        VStack(spacing: 8) {
            Text("Solved! 🎉").font(.title2.weight(.bold)).foregroundStyle(.green)
            let under = engine.chain.count - 1 <= engine.parSteps
            Text(under ? "Under par — excellent!" : "Solved in \(engine.chain.count - 1) steps (par \(engine.parSteps))")
                .font(.callout).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func submit() {
        engine.submit(word: input)
        if engine.errorMessage.isEmpty { input = "" }
        if pref?.hapticsEnabled ?? true {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func saveResult() {
        let r = RungResult(
            mode: "daily",
            startWord: engine.startWord,
            targetWord: engine.targetWord,
            steps: engine.chain.count - 1,
            parSteps: engine.parSteps,
            solved: engine.isSolved,
            durationSeconds: engine.elapsedSeconds
        )
        ctx.insert(r)
    }

    private func timeString(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }
}
