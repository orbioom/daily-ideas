import SwiftUI
import SwiftData

struct QuizView: View {
    @Query private var progressList: [AtomProgress]
    @Query private var prefsList: [AtomPrefs]
    @Environment(\.modelContext) private var modelContext

    @State private var engine = QuizEngine()
    @State private var isSessionActive = false
    @State private var showingProAlert = false
    @State private var sessionComplete = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: AtomProgress {
        if let p = progressList.first { return p }
        let p = AtomProgress(); modelContext.insert(p); return p
    }
    private var prefs: AtomPrefs {
        if let p = prefsList.first { return p }
        let p = AtomPrefs(); modelContext.insert(p); return p
    }

    var body: some View {
        NavigationStack {
            if !isSessionActive {
                modeSelectionView
            } else if sessionComplete {
                QuizResultView(engine: engine) {
                    endSession()
                } onRestart: {
                    restartSession()
                }
            } else {
                activeQuizView
            }
        }
    }

    // MARK: - Mode Selection

    private var modeSelectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 52))
                        .foregroundStyle(AtomTheme.accent)
                    Text("Chemistry Quiz")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(AtomTheme.textPrimary)
                    Text("Test your knowledge of the elements")
                        .font(.subheadline)
                        .foregroundStyle(AtomTheme.textSecondary)
                }
                .padding(.top, 32)

                // Mode cards
                VStack(spacing: 12) {
                    ForEach(QuizEngine.QuizMode.allCases, id: \.rawValue) { mode in
                        QuizModeCard(
                            mode: mode,
                            isSelected: engine.quizMode == mode,
                            isPro: mode.isPro && !prefs.isPro
                        ) {
                            if mode.isPro && !prefs.isPro {
                                showingProAlert = true
                            } else {
                                engine.quizMode = mode
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Start button
                Button {
                    startSession()
                } label: {
                    Label("Start Quiz", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AtomButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .background(AtomTheme.background)
        .navigationTitle("Quiz")
        .alert("Pro Feature", isPresented: $showingProAlert) {
            Button("Unlock Pro — $3.99") { prefs.isPro = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Atomic Mass quiz is part of Atom Pro. Unlock all quiz modes and full stats history.")
        }
    }

    // MARK: - Active Quiz

    @ViewBuilder
    private var activeQuizView: some View {
        VStack(spacing: 0) {
            // Progress bar
            quizHeader

            if let question = engine.currentQuestion {
                quizQuestionView(question)
            } else {
                ProgressView()
                    .tint(AtomTheme.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(AtomTheme.background)
        .navigationTitle("Question \(engine.questionsAnswered + 1)")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("End") {
                    finishSession()
                }
                .foregroundStyle(AtomTheme.textSecondary)
            }
        }
        .onAppear {
            if engine.currentQuestion == nil {
                engine.generateQuestion()
            }
        }
    }

    private var quizHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Label("\(engine.correctCount)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(AtomTheme.success)
                Spacer()
                Label("\(engine.currentStreak)", systemImage: "flame.fill")
                    .foregroundStyle(AtomTheme.warning)
                Spacer()
                Label("\(engine.wrongCount)", systemImage: "xmark.circle.fill")
                    .foregroundStyle(AtomTheme.error)
            }
            .font(.subheadline.bold())
            .padding(.horizontal, 24)

            // Progress
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AtomTheme.cardBackground)
                        .frame(height: 6)
                    let total = max(engine.questionsAnswered, 1)
                    let ratio = CGFloat(engine.correctCount) / CGFloat(total)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AtomTheme.accent)
                        .frame(width: geo.size.width * ratio, height: 6)
                        .animation(.spring(), value: ratio)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 12)
        .background(AtomTheme.cardBackground)
    }

    @ViewBuilder
    private func quizQuestionView(_ question: QuizEngine.QuizQuestion) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Mode badge
                Text(question.mode.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(AtomTheme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(AtomTheme.accent.opacity(0.15))
                    .clipShape(Capsule())

                // Question prompt
                VStack(spacing: 8) {
                    Text(question.questionText)
                        .font(.subheadline)
                        .foregroundStyle(AtomTheme.textSecondary)

                    if question.mode == .symbolToName {
                        // Large symbol display
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(question.element.category.color.opacity(0.25))
                                .frame(width: 140, height: 140)
                            VStack(spacing: 4) {
                                Text("\(question.element.atomicNumber)")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(AtomTheme.textSecondary)
                                Text(question.prompt)
                                    .font(.system(size: 72, weight: .bold))
                                    .foregroundStyle(question.element.category.color)
                            }
                        }
                    } else {
                        Text(question.prompt)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(AtomTheme.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.vertical, 8)

                // Answer options
                VStack(spacing: 12) {
                    ForEach(question.options, id: \.self) { option in
                        AnswerOptionButton(
                            text: option,
                            selectedAnswer: engine.selectedAnswer,
                            correctAnswer: question.correctAnswer,
                            onTap: {
                                handleAnswer(option, question: question)
                            }
                        )
                        .accessibilityLabel("Option: \(option)")
                    }
                }
                .padding(.horizontal, 24)

                // Result feedback
                if engine.showingResult, let selected = engine.selectedAnswer {
                    let correct = selected == question.correctAnswer
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(correct ? AtomTheme.success : AtomTheme.error)
                                .font(.title2)
                            Text(correct ? "Correct!" : "Incorrect")
                                .font(.headline)
                                .foregroundStyle(correct ? AtomTheme.success : AtomTheme.error)
                        }
                        if !correct {
                            Text("Answer: \(question.correctAnswer)")
                                .font(.subheadline)
                                .foregroundStyle(AtomTheme.textSecondary)
                        }

                        Button {
                            handleNextQuestion()
                        } label: {
                            Text("Next Question")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(AtomButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.top, 16)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: engine.showingResult)
        }
    }

    // MARK: - Actions

    private func startSession() {
        engine = QuizEngine()
        engine.quizMode = prefs.defaultQuizModeEnum
        isSessionActive = true
        sessionComplete = false
        engine.generateQuestion()
    }

    private func restartSession() {
        engine.reset()
        sessionComplete = false
        engine.generateQuestion()
    }

    private func handleAnswer(_ option: String, question: QuizEngine.QuizQuestion) {
        guard engine.selectedAnswer == nil else { return }
        let correct = engine.answer(option)
        let announcement = correct ? "Correct!" : "Incorrect. The answer is \(question.correctAnswer)"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }

    private func handleNextQuestion() {
        if engine.questionsAnswered >= 10 {
            finishSession()
        } else {
            engine.nextQuestion()
        }
    }

    private func finishSession() {
        progress.recordQuizResult(
            correct: engine.correctCount,
            total: engine.questionsAnswered,
            mode: engine.quizMode.rawValue,
            engine: engine
        )
        sessionComplete = true
    }

    private func endSession() {
        isSessionActive = false
        sessionComplete = false
        engine.reset()
    }
}

// MARK: - Answer Option Button

struct AnswerOptionButton: View {
    let text: String
    let selectedAnswer: String?
    let correctAnswer: String
    let onTap: () -> Void

    private var isSelected: Bool { selectedAnswer == text }
    private var isAnswered: Bool { selectedAnswer != nil }
    private var isCorrect: Bool { text == correctAnswer }

    private var bgColor: Color {
        guard isAnswered else { return AtomTheme.cardBackground }
        if isCorrect { return AtomTheme.success.opacity(0.25) }
        if isSelected { return AtomTheme.error.opacity(0.25) }
        return AtomTheme.cardBackground
    }

    private var borderColor: Color {
        guard isAnswered else { return AtomTheme.cellBorder }
        if isCorrect { return AtomTheme.success }
        if isSelected { return AtomTheme.error }
        return AtomTheme.cellBorder
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(text)
                    .font(.body)
                    .foregroundStyle(AtomTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isAnswered {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AtomTheme.success)
                    } else if isSelected {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AtomTheme.error)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1.5)
            )
        }
        .disabled(isAnswered)
        .animation(.easeInOut(duration: 0.15), value: isAnswered)
    }
}

// MARK: - Mode Card

struct QuizModeCard: View {
    let mode: QuizEngine.QuizMode
    let isSelected: Bool
    let isPro: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: mode.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? AtomTheme.accent : AtomTheme.textSecondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(mode.rawValue)
                            .font(.headline)
                            .foregroundStyle(AtomTheme.textPrimary)
                        if isPro {
                            Text("PRO")
                                .font(.caption2.bold())
                                .foregroundStyle(AtomTheme.warning)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AtomTheme.warning.opacity(0.20))
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AtomTheme.accent)
                }
            }
            .padding(16)
            .background(isSelected ? AtomTheme.accent.opacity(0.10) : AtomTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AtomTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AtomTheme.cornerRadius)
                    .stroke(isSelected ? AtomTheme.accent : AtomTheme.cellBorder, lineWidth: 1.5)
            )
        }
    }
}

#Preview {
    QuizView()
        .modelContainer(for: [AtomProgress.self, AtomPrefs.self])
        .preferredColorScheme(.dark)
}
