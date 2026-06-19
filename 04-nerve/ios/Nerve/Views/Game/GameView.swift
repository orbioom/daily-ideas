import SwiftUI
import SwiftData

@Observable
class GameSession {
    var difficulty: Difficulty = .medium
    var secretCode: [Int] = []
    var guesses: [[Int]] = []
    var feedbacks: [[Int]] = []
    var currentGuess: [Int] = []
    var isComplete = false
    var isSolved = false
    var showResult = false
    var startTime: Date = Date()
    var elapsedSeconds: Int = 0

    func newGame(difficulty: Difficulty) {
        self.difficulty = difficulty
        secretCode = NerveEngine.generateCode(difficulty: difficulty)
        guesses = []
        feedbacks = []
        currentGuess = []
        isComplete = false
        isSolved = false
        showResult = false
        startTime = Date()
        elapsedSeconds = 0
    }

    func submitGuess() {
        guard currentGuess.count == difficulty.codeLength, !isComplete else { return }
        let fb = NerveEngine.evaluate(guess: currentGuess, secret: secretCode)
        guesses.append(currentGuess)
        feedbacks.append(NerveEngine.encodeFeedback(black: fb.black, white: fb.white))
        currentGuess = []
        elapsedSeconds = Int(Date().timeIntervalSince(startTime))
        if fb.black == difficulty.codeLength {
            isSolved = true
            isComplete = true
            showResult = true
        } else if guesses.count >= NerveEngine.maxGuesses {
            isComplete = true
            showResult = true
        }
    }
}

struct GameView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("preferredDifficulty") private var preferredDifficulty = "Medium"
    @State private var session = GameSession()
    @State private var showDifficultyPicker = false
    @State private var timer: Timer? = nil

    var difficulty: Difficulty {
        Difficulty(rawValue: preferredDifficulty) ?? .medium
    }

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.05, blue: 0.16).ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(0..<NerveEngine.maxGuesses, id: \.self) { row in
                                let isActive = row == session.guesses.count && !session.isComplete
                                let hasGuess = row < session.guesses.count
                                GuessRowView(
                                    guess: hasGuess ? session.guesses[row] : (isActive ? session.currentGuess : []),
                                    feedback: hasGuess ? session.feedbacks[row] : [],
                                    codeLength: session.difficulty.codeLength,
                                    isActive: isActive
                                )
                                .id(row)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onChange(of: session.guesses.count) { _, count in
                        withAnimation {
                            proxy.scrollTo(min(count, NerveEngine.maxGuesses - 1))
                        }
                    }
                }

                if !session.isComplete {
                    ColorPickerBarView(
                        colorCount: session.difficulty.colorCount,
                        codeLength: session.difficulty.codeLength,
                        currentGuess: $session.currentGuess,
                        onSubmit: {
                            session.submitGuess()
                            if session.isComplete {
                                saveRecord()
                                stopTimer()
                            }
                        }
                    )
                }
            }
        }
        .onAppear {
            if session.secretCode.isEmpty {
                session.newGame(difficulty: difficulty)
            }
            startTimer()
        }
        .onDisappear { stopTimer() }
        .sheet(isPresented: $session.showResult) {
            ResultSheet(session: session) {
                session.newGame(difficulty: difficulty)
                startTimer()
            }
        }
        .sheet(isPresented: $showDifficultyPicker) {
            DifficultyPickerSheet(selected: $preferredDifficulty) {
                session.newGame(difficulty: difficulty)
                startTimer()
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Button(action: { showDifficultyPicker = true }) {
                Label(session.difficulty.rawValue, systemImage: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
            }

            Spacer()

            Text(timeString)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            Button(action: {
                session.newGame(difficulty: difficulty)
                startTimer()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var timeString: String {
        let s = session.elapsedSeconds
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if !session.isComplete {
                session.elapsedSeconds = Int(Date().timeIntervalSince(session.startTime))
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func saveRecord() {
        let record = GameRecord(difficulty: session.difficulty.rawValue, secretCode: session.secretCode)
        record.guesses = session.guesses
        record.feedbacks = session.feedbacks
        record.isSolved = session.isSolved
        record.elapsedSeconds = session.elapsedSeconds
        modelContext.insert(record)
        try? modelContext.save()
    }
}

struct ResultSheet: View {
    let session: GameSession
    let onNewGame: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.05, blue: 0.16).ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image(systemName: session.isSolved ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(session.isSolved ? .green : .red)

                VStack(spacing: 8) {
                    Text(session.isSolved ? "Cracked!" : "Not This Time")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    if session.isSolved {
                        Text("\(session.guesses.count) guess\(session.guesses.count == 1 ? "" : "es") · \(timeString)")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    } else {
                        Text("The code was:")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                        HStack(spacing: 8) {
                            ForEach(0..<session.secretCode.count, id: \.self) { i in
                                PegView(colorIndex: session.secretCode[i], size: 36)
                            }
                        }
                    }
                }

                HStack(spacing: 16) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Review")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button(action: {
                        dismiss()
                        onNewGame()
                    }) {
                        Text("New Game")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
    }

    private var timeString: String {
        let s = session.elapsedSeconds
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

struct DifficultyPickerSheet: View {
    @Binding var selected: String
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.05, blue: 0.16).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Difficulty")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 24)

                ForEach(Difficulty.allCases) { d in
                    Button(action: {
                        selected = d.rawValue
                        dismiss()
                        onConfirm()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(d.rawValue)
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(d.description)
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            Spacer()
                            if selected == d.rawValue {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.purple)
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(selected == d.rawValue ? 0.12 : 0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
        }
    }
}
