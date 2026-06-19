import SwiftUI
import SwiftData

struct DailyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyResult.dateString, order: .reverse) private var results: [DailyResult]
    @State private var session: DailySession? = nil
    @State private var showGame = false

    private var todayString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    private var todayResult: DailyResult? {
        results.first { $0.dateString == todayString }
    }

    private var streak: Int {
        var s = 0
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        var check = Date()
        for _ in 0..<365 {
            let ds = fmt.string(from: check)
            if results.contains(where: { $0.dateString == ds && $0.isSolved }) {
                s += 1
                check = Calendar.current.date(byAdding: .day, value: -1, to: check) ?? check
            } else {
                break
            }
        }
        return s
    }

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.05, blue: 0.16).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 6) {
                        Text("Daily Challenge")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(formattedDate)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.top, 20)

                    // Streak badge
                    HStack(spacing: 24) {
                        statTile(value: "\(streak)", label: "Streak", symbol: "flame.fill", color: .orange)
                        statTile(value: "\(results.filter(\.isSolved).count)", label: "Solved", symbol: "checkmark.circle.fill", color: .green)
                        statTile(value: "\(results.count)", label: "Played", symbol: "gamecontroller.fill", color: .purple)
                    }
                    .padding(.horizontal, 20)

                    if let result = todayResult {
                        completedCard(result: result)
                    } else {
                        playCard
                    }

                    if !results.isEmpty {
                        pastResultsSection
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showGame, onDismiss: { session = nil }) {
            if let s = session {
                DailyGameView(session: s) { guessCount, solved, elapsed in
                    let result = DailyResult(dateString: todayString, guessCount: guessCount, isSolved: solved, elapsedSeconds: elapsed)
                    modelContext.insert(result)
                    try? modelContext.save()
                    showGame = false
                }
            }
        }
    }

    private var formattedDate: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .long
        return fmt.string(from: Date())
    }

    private var playCard: some View {
        Button(action: {
            let seed = NerveEngine.dailySeed()
            let code = NerveEngine.generateCode(difficulty: .medium, seed: seed)
            session = DailySession(code: code)
            showGame = true
        }) {
            VStack(spacing: 16) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.purple)
                Text("Play Today's Puzzle")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("4 pegs · 8 colors · same for everyone")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.purple.opacity(0.5), lineWidth: 1))
        }
        .padding(.horizontal, 20)
    }

    private func completedCard(result: DailyResult) -> some View {
        VStack(spacing: 12) {
            Image(systemName: result.isSolved ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(result.isSolved ? .green : .red)
            Text(result.isSolved ? "Solved!" : "Better luck tomorrow")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            if result.isSolved {
                Text("\(result.guessCount) guess\(result.guessCount == 1 ? "" : "es") · \(timeStr(result.elapsedSeconds))")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 20)
    }

    private var pastResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Results")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 20)

            ForEach(results.prefix(7)) { r in
                HStack {
                    Image(systemName: r.isSolved ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(r.isSolved ? .green : .red)
                    Text(r.dateString)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    if r.isSolved {
                        Text("\(r.guessCount) guesses")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Text(timeStr(r.elapsedSeconds))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 20)
            }
        }
    }

    private func statTile(value: String, label: String, symbol: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func timeStr(_ s: Int) -> String { String(format: "%d:%02d", s / 60, s % 60) }
}

class DailySession: ObservableObject {
    let code: [Int]
    @Published var guesses: [[Int]] = []
    @Published var feedbacks: [[Int]] = []
    @Published var currentGuess: [Int] = []
    @Published var isSolved = false
    @Published var isComplete = false
    let startTime = Date()

    init(code: [Int]) { self.code = code }

    func submit() {
        guard currentGuess.count == code.count else { return }
        let fb = NerveEngine.evaluate(guess: currentGuess, secret: code)
        guesses.append(currentGuess)
        feedbacks.append([fb.black, fb.white])
        currentGuess = []
        if fb.black == code.count { isSolved = true; isComplete = true }
        else if guesses.count >= NerveEngine.maxGuesses { isComplete = true }
    }
}

struct DailyGameView: View {
    @ObservedObject var session: DailySession
    let onComplete: (Int, Bool, Int) -> Void
    @State private var elapsed = 0
    @State private var timer: Timer? = nil
    @State private var showResult = false

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.05, blue: 0.16).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("Daily Challenge")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(String(format: "%d:%02d", elapsed / 60, elapsed % 60))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(0..<NerveEngine.maxGuesses, id: \.self) { row in
                            let isActive = row == session.guesses.count && !session.isComplete
                            let hasGuess = row < session.guesses.count
                            GuessRowView(
                                guess: hasGuess ? session.guesses[row] : (isActive ? session.currentGuess : []),
                                feedback: hasGuess ? session.feedbacks[row] : [],
                                codeLength: session.code.count,
                                isActive: isActive
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }

                if !session.isComplete {
                    ColorPickerBarView(
                        colorCount: 8,
                        codeLength: session.code.count,
                        currentGuess: Binding(get: { session.currentGuess }, set: { session.currentGuess = $0 }),
                        onSubmit: {
                            session.submit()
                            if session.isComplete {
                                stopTimer()
                                showResult = true
                            }
                        }
                    )
                }
            }
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
        .sheet(isPresented: $showResult) {
            ZStack {
                Color(red: 0.07, green: 0.05, blue: 0.16).ignoresSafeArea()
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: session.isSolved ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(session.isSolved ? .green : .red)
                    Text(session.isSolved ? "Daily Solved!" : "Tomorrow's another day")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    if !session.isSolved {
                        HStack(spacing: 8) {
                            ForEach(0..<session.code.count, id: \.self) { i in
                                PegView(colorIndex: session.code[i], size: 36)
                            }
                        }
                    }
                    Button(action: { onComplete(session.guesses.count, session.isSolved, elapsed) }) {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 32)
                    Spacer()
                }
            }
            .interactiveDismissDisabled()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsed = Int(Date().timeIntervalSince(session.startTime))
        }
    }
    private func stopTimer() { timer?.invalidate(); timer = nil }
}
