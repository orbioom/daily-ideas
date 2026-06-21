import SwiftUI
import SwiftData

struct QuizView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = QuizViewModel()
    @Query private var settingsList: [FlopSettings]

    private var settings: FlopSettings {
        settingsList.first ?? FlopSettings()
    }

    var body: some View {
        ZStack {
            FlopTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                statsBar.padding(.horizontal, 20).padding(.top, 12)
                Spacer()
                positionBadge
                    .padding(.bottom, 16)
                cardDisplay
                    .padding(.bottom, 32)
                actionButtons
                    .padding(.horizontal, 24)
                if vm.showResult {
                    resultPanel
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                Spacer()
                if vm.showResult {
                    nextButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: vm.showResult)
        .navigationTitle("Hand Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FlopTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    var statsBar: some View {
        HStack(spacing: 0) {
            statChip(label: "Accuracy", value: vm.sessionTotal == 0 ? "—" : "\(Int(vm.accuracy))%")
            Spacer()
            statChip(label: "Hands", value: "\(vm.sessionTotal)")
            Spacer()
            statChip(label: "Streak", value: "\(vm.streak) 🔥")
            Spacer()
            statChip(label: "Best", value: "\(vm.bestStreak)")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(FlopTheme.felt.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
    }

    func statChip(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(FlopTheme.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(FlopTheme.textSecondary)
        }
    }

    var positionBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(FlopTheme.positionColors[vm.currentHand.position] ?? FlopTheme.accent)
                .frame(width: 10, height: 10)
            Text(vm.currentHand.position.fullName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(FlopTheme.textPrimary)
            Text("(\(vm.currentHand.position.rawValue))")
                .font(.system(size: 13))
                .foregroundStyle(FlopTheme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(FlopTheme.felt, in: Capsule())
    }

    var cardDisplay: some View {
        HStack(spacing: 20) {
            CardView(card: vm.currentHand.card1, revealed: true)
            CardView(card: vm.currentHand.card2, revealed: true)
        }
        .padding(.horizontal, 40)
    }

    var actionButtons: some View {
        HStack(spacing: 12) {
            ForEach(PreFlopAction.allCases, id: \.self) { action in
                actionButton(action)
            }
        }
    }

    func actionButton(_ action: PreFlopAction) -> some View {
        let isSelected = vm.selectedAction == action
        let color = buttonColor(for: action)
        return Button {
            vm.answer(action)
            saveRecord()
        } label: {
            Text(action.rawValue)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isSelected ? .black : color)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isSelected ? color : color.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.6), lineWidth: 1.5))
        }
        .disabled(vm.showResult)
        .animation(.easeInOut(duration: 0.2), value: vm.showResult)
        .accessibilityLabel("\(action.rawValue) action")
    }

    func buttonColor(for action: PreFlopAction) -> Color {
        switch action {
        case .raise: return FlopTheme.accentGold
        case .call: return FlopTheme.accent
        case .fold: return FlopTheme.wrongRed
        }
    }

    var resultPanel: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: vm.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(vm.isCorrect ? FlopTheme.correctGreen : FlopTheme.wrongRed)
                Text(vm.isCorrect ? "Correct!" : "Incorrect")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(vm.isCorrect ? FlopTheme.correctGreen : FlopTheme.wrongRed)
                if !vm.isCorrect {
                    Text("→ \(vm.currentHand.correctAction.rawValue)")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(FlopTheme.accentGold)
                }
            }
            if settings.showExplanations {
                Text(vm.currentHand.explanation)
                    .font(.system(size: 14))
                    .foregroundStyle(FlopTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(FlopTheme.felt, in: RoundedRectangle(cornerRadius: 16))
    }

    var nextButton: some View {
        Button("Next Hand") {
            vm.nextHand()
        }
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(FlopTheme.accent, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel("Next hand")
    }

    func saveRecord() {
        guard let action = vm.selectedAction else { return }
        let record = FlopQuizRecord(
            handName: vm.currentHand.handName,
            position: vm.currentHand.position.rawValue,
            wasCorrect: action == vm.currentHand.correctAction
        )
        modelContext.insert(record)
    }
}

struct CardView: View {
    let card: PlayingCard
    let revealed: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(revealed ? Color.white : FlopTheme.card)
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
            if revealed {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(card.rank.shortName)
                                .font(.system(size: 22, weight: .bold))
                            Text(card.suit.symbol)
                                .font(.system(size: 18))
                        }
                        .foregroundStyle(card.suit.isRed ? FlopTheme.suitRed : Color.black)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                    Spacer()
                    Text(card.suit.symbol)
                        .font(.system(size: 44))
                        .foregroundStyle(card.suit.isRed ? FlopTheme.suitRed : Color.black)
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(card.suit.symbol)
                                .font(.system(size: 18))
                            Text(card.rank.shortName)
                                .font(.system(size: 22, weight: .bold))
                        }
                        .foregroundStyle(card.suit.isRed ? FlopTheme.suitRed : Color.black)
                        .rotationEffect(.degrees(180))
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                }
            }
        }
        .frame(width: 120, height: 170)
        .accessibilityLabel("\(card.rank.shortName) of \(card.suit.rawValue)")
    }
}
