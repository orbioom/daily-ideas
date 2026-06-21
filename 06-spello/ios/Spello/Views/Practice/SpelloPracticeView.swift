import SwiftUI
import SwiftData

struct SpelloPracticeView: View {
    @Query private var profiles: [SpelloProfile]
    @Query private var prefs: [SpelloPrefs]
    @Environment(\.modelContext) private var ctx
    @State private var engine = SpelloEngine()
    @State private var selectedMode: SpelloMode = .quiz
    @State private var isStarted = false
    @State private var showResult = false

    private let accent = Color(red: 0.95, green: 0.55, blue: 0.15)

    private var activeProfile: SpelloProfile? {
        guard let id = prefs.first?.activeProfileId else { return profiles.first }
        return profiles.first(where: { $0.id == id }) ?? profiles.first
    }

    var body: some View {
        NavigationStack {
            if !isStarted {
                modeSelect
            } else if showResult {
                resultView
            } else {
                questionView
            }
        }
    }

    // MARK: - Mode Select

    private var modeSelect: some View {
        VStack(spacing: 24) {
            if let p = activeProfile {
                Text("Practice for \(p.name)").font(.headline).foregroundStyle(.secondary)
            }
            Text("Choose Mode").font(.title2.weight(.bold))
            VStack(spacing: 12) {
                ForEach(SpelloMode.allCases, id: \.self) { mode in
                    modeButton(mode)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Practice")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: engine.isFinished) { _, finished in
            if finished { showResult = true }
        }
    }

    private func modeButton(_ mode: SpelloMode) -> some View {
        Button(action: { startSession(mode: mode) }) {
            HStack {
                Image(systemName: modeIcon(mode))
                    .font(.title3)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.rawValue).font(.headline)
                    Text(modeDesc(mode)).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.primary)
        }
    }

    private func modeIcon(_ mode: SpelloMode) -> String {
        switch mode {
        case .quiz: return "checklist"
        case .fill: return "keyboard"
        case .listen: return "speaker.wave.2.fill"
        }
    }

    private func modeDesc(_ mode: SpelloMode) -> String {
        switch mode {
        case .quiz: return "Pick the correctly-spelled word"
        case .fill: return "Type out the spelling yourself"
        case .listen: return "Hear the word, then spell it"
        }
    }

    // MARK: - Question View

    private var questionView: some View {
        VStack(spacing: 20) {
            progressHeader.padding(.horizontal)
            Spacer()
            if engine.mode == .quiz {
                quizView
            } else {
                typeView
            }
            Spacer()
        }
        .navigationTitle(engine.mode.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Quit") { isStarted = false }
                    .foregroundStyle(.red)
            }
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 6) {
            ProgressView(value: Double(engine.questionIndex), total: Double(engine.total))
                .tint(accent)
            HStack {
                Text("Question \(engine.questionIndex + 1) of \(engine.total)")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("Score: \(engine.score)").font(.caption.weight(.semibold))
            }
        }
    }

    private var quizView: some View {
        VStack(spacing: 20) {
            if let q = engine.currentQuestion {
                Text(q.word)
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(accent)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)

                VStack(spacing: 10) {
                    ForEach(q.choices, id: \.self) { choice in
                        choiceButton(choice, word: q.word)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func choiceButton(_ choice: String, word: String) -> some View {
        let submitted = engine.isCorrect != nil
        let isTarget = choice == word
        let isSelected = submitted && (isTarget || (engine.isCorrect == false && choice == engine.userInput))
        let bg: Color = submitted
            ? (isTarget ? .green : (isSelected ? .red : Color(.systemGray6)))
            : Color(.systemGray6)

        return Button(action: {
            guard engine.isCorrect == nil else { return }
            engine.userInput = choice
            engine.submitChoice(choice)
        }) {
            Text(choice)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(bg)
                .foregroundStyle(submitted && (isTarget || isSelected) ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(submitted)
    }

    private var typeView: some View {
        VStack(spacing: 20) {
            if let q = engine.currentQuestion {
                if engine.mode == .listen {
                    Button(action: { engine.repeatWord() }) {
                        VStack(spacing: 8) {
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(accent)
                            Text("Tap to hear the word")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text(q.word)
                        .font(.system(size: 36, weight: .black))
                        .foregroundStyle(accent)
                }

                TextField("Type your answer…", text: $engine.userInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .disabled(engine.isCorrect != nil)

                if let correct = engine.isCorrect {
                    HStack {
                        Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(correct ? "Correct!" : "The answer was: \(q.word)")
                    }
                    .foregroundStyle(correct ? .green : .red)
                    .font(.headline)
                } else {
                    Button("Submit") { engine.submitTyped() }
                        .buttonStyle(.borderedProminent)
                        .tint(accent)
                        .disabled(engine.userInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .padding()
    }

    // MARK: - Result View

    private var resultView: some View {
        VStack(spacing: 24) {
            Image(systemName: engine.accuracy >= 0.8 ? "star.fill" : "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(engine.accuracy >= 0.8 ? .yellow : accent)
            Text("Session Complete!").font(.title.weight(.bold))
            Text("\(engine.score) / \(engine.total) correct")
                .font(.title2)
                .foregroundStyle(accent)
            Text(String(format: "%.0f%% accuracy", engine.accuracy * 100))
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                Button("Try Again") { startSession(mode: engine.mode) }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                Button("Done") { isStarted = false }
                    .buttonStyle(.bordered)
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { saveSession() }
    }

    // MARK: - Helpers

    private func startSession(mode: SpelloMode) {
        let grade = activeProfile?.gradeLevel ?? 1
        engine.startSession(mode: mode, gradeLevel: grade, count: 10)
        isStarted = true
        showResult = false
    }

    private func saveSession() {
        guard let p = activeProfile else { return }
        let s = SpelloSession(
            profileId: p.id,
            mode: engine.mode.rawValue,
            gradeLevel: engine.gradeLevel,
            totalWords: engine.total,
            correctWords: engine.score
        )
        ctx.insert(s)
    }
}
