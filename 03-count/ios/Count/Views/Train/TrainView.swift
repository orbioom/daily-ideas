import SwiftUI
import SwiftData

struct TrainView: View {
    @Query private var settingsArr: [CountSettings]
    @Environment(\.modelContext) private var modelContext
    @State private var vm = TrainViewModel()
    @State private var dealerSuit: String = randomSuit(for: Int.random(in: 1...10))
    @State private var playerSuit0: String = randomSuit(for: Int.random(in: 1...10))
    @State private var playerSuit1: String = randomSuit(for: Int.random(in: 1...10))
    @State private var cardScale: Double = 1.0
    @State private var resultOpacity: Double = 0.0

    private var settings: CountSettings? { settingsArr.first }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [CountTheme.gradientStart, CountTheme.tableGreen],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    sessionStatsBar
                        .padding(.horizontal)
                        .padding(.top, 8)

                    dealerSection
                        .padding(.top, 24)

                    dividerLine

                    playerSection
                        .padding(.top, 16)

                    scenarioLabel
                        .padding(.top, 12)

                    Spacer()

                    if vm.showResult {
                        resultPanel
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                    } else {
                        actionButtons
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("Train")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation { vm.resetSession() }
                        refreshSuits()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .onAppear {
            if let s = settings { vm.difficulty = s.difficulty }
        }
    }

    private var sessionStatsBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Session Accuracy")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text("\(vm.sessionCorrect)/\(vm.sessionTotal)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                Text("(\(Int(vm.accuracy * 100))%)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
            ProgressView(value: vm.accuracy)
                .tint(vm.accuracy >= 0.8 ? CountTheme.correctGreen : (vm.accuracy >= 0.5 ? .yellow : CountTheme.wrongRed))
                .background(Color.white.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(12)
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var dealerSection: some View {
        VStack(spacing: 8) {
            Text("DEALER")
                .font(.caption2.bold())
                .tracking(2)
                .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 16) {
                CardFaceView(cardValue: vm.scenario.dealerUpcard, suit: dealerSuit, isDealer: true)
                    .scaleEffect(cardScale)
                CardBackView(isDealer: true)
            }
        }
    }

    private var dividerLine: some View {
        HStack {
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)
                .padding(.horizontal, 24)
                .padding(.top, 20)
        }
    }

    private var playerSection: some View {
        VStack(spacing: 8) {
            Text("YOUR HAND")
                .font(.caption2.bold())
                .tracking(2)
                .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 16) {
                CardFaceView(
                    cardValue: vm.scenario.playerCards[0],
                    suit: playerSuit0
                )
                .scaleEffect(cardScale)
                CardFaceView(
                    cardValue: vm.scenario.playerCards[1],
                    suit: playerSuit1
                )
                .scaleEffect(cardScale)
            }
        }
    }

    private var scenarioLabel: some View {
        VStack(spacing: 4) {
            Text(vm.scenario.displayString)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Group {
                if vm.scenario.isPair {
                    Text("Pair")
                        .foregroundStyle(.yellow.opacity(0.9))
                } else if vm.scenario.isSoft {
                    Text("Soft \(vm.scenario.softTotal)")
                        .foregroundStyle(.cyan.opacity(0.9))
                } else {
                    Text("Hard \(vm.scenario.hardTotal)")
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .font(.caption.bold())
        }
    }

    private var actionButtons: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach([BJAction.hit, .stand, .double, .split], id: \.self) { action in
                ActionButton(action: action) {
                    withAnimation(.spring(response: 0.35)) {
                        vm.choose(
                            action,
                            context: modelContext,
                            showCorrectOnWrong: settings?.showCorrectOnWrong ?? true,
                            haptic: settings?.hapticEnabled ?? true
                        )
                    }
                }
            }
        }
    }

    private var resultPanel: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: vm.lastWasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(vm.lastWasCorrect ? CountTheme.correctGreen : CountTheme.wrongRed)

                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.lastWasCorrect ? "Correct!" : "Incorrect")
                        .font(.headline)
                        .foregroundStyle(vm.lastWasCorrect ? CountTheme.correctGreen : CountTheme.wrongRed)
                    if !vm.lastWasCorrect, let correct = vm.lastResult {
                        Text("Correct play: \(correct.rawValue)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                Spacer()
            }

            Button {
                withAnimation(.spring(response: 0.35)) {
                    vm.next()
                }
                refreshSuits()
            } label: {
                Text("Next Hand")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(CountTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    vm.lastWasCorrect ? CountTheme.correctGreen.opacity(0.5) : CountTheme.wrongRed.opacity(0.5),
                    lineWidth: 1.5
                )
        )
    }

    private func refreshSuits() {
        dealerSuit = ["spade", "heart", "diamond", "club"].randomElement()!
        playerSuit0 = ["spade", "heart", "diamond", "club"].randomElement()!
        playerSuit1 = ["spade", "heart", "diamond", "club"].randomElement()!
        withAnimation(.spring(response: 0.4)) {
            cardScale = 0.92
        }
        withAnimation(.spring(response: 0.4).delay(0.1)) {
            cardScale = 1.0
        }
    }
}

struct ActionButton: View {
    let action: BJAction
    let onTap: () -> Void
    @State private var isPressed: Bool = false

    private var buttonColor: Color {
        switch action {
        case .hit: return Color(red: 0.20, green: 0.55, blue: 0.85)
        case .stand: return Color(red: 0.85, green: 0.35, blue: 0.20)
        case .double: return Color(red: 0.75, green: 0.55, blue: 0.10)
        case .split: return Color(red: 0.55, green: 0.25, blue: 0.75)
        case .surrender: return Color(red: 0.50, green: 0.50, blue: 0.55)
        }
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.2)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.2)) { isPressed = false }
            }
            onTap()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: action.systemImage)
                    .font(.system(size: 22))
                Text(action.rawValue)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(buttonColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .shadow(color: buttonColor.opacity(0.4), radius: 5, y: 3)
        }
    }
}
