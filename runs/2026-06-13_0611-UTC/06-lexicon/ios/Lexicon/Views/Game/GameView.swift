import SwiftUI

struct GameView: View {
    var vm: GameViewModel
    let title: String
    var resultPrimaryLabel: String = "Done"
    var onResultPrimary: () -> Void = {}

    @State private var showResult = false

    var body: some View {
        VStack(spacing: 0) {
            messageBar
            BoardView(guesses: vm.guesses, rows: vm.rows, current: vm.current, shakeTrigger: vm.shakeRow)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .layoutPriority(1)
            KeyboardView(states: vm.keyboardStates,
                         onKey: { vm.type($0) },
                         onEnter: { vm.submit() },
                         onDelete: { vm.backspace() })
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onChange(of: vm.status) { _, status in
            if status != .playing {
                if status == .won { Haptics.success() } else { Haptics.warning() }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showResult = true }
            }
        }
        .onAppear { if vm.status != .playing { showResult = true } }
        .sheet(isPresented: $showResult) {
            ResultSheet(vm: vm, title: title,
                        primaryLabel: resultPrimaryLabel, onPrimary: onResultPrimary)
                .presentationDetents([.medium])
        }
    }

    private var messageBar: some View {
        ZStack {
            if let message = vm.message, vm.status == .playing {
                Text(message)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Theme.ink))
                    .transition(.opacity)
            }
        }
        .frame(height: 34)
        .animation(.easeInOut(duration: 0.2), value: vm.message)
    }
}

struct ResultSheet: View {
    var vm: GameViewModel
    let title: String
    let primaryLabel: String
    let onPrimary: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var won: Bool { vm.status == .won }

    var body: some View {
        VStack(spacing: 18) {
            Capsule().fill(Theme.hairline).frame(width: 40, height: 5).padding(.top, 8)
            Image(systemName: won ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.system(size: 46)).foregroundStyle(won ? Theme.correct : Theme.absent)
            Text(won ? winHeadline : "Out of guesses")
                .font(Theme.rounded(24)).foregroundStyle(Theme.ink)
            if !won {
                Text("The word was “\(vm.answer.uppercased())”.")
                    .font(.system(size: 16)).foregroundStyle(Theme.inkSoft)
            } else {
                Text("Solved in \(vm.guesses.count) / \(WordGame.maxRows).")
                    .font(.system(size: 16)).foregroundStyle(Theme.inkSoft)
            }
            Text(vm.rows.map { $0.map(\.emoji).joined() }.joined(separator: "\n"))
                .font(.system(size: 18)).lineSpacing(2)
            Spacer()
            HStack(spacing: 12) {
                ShareLink(item: ShareCard.text(title: title, rows: vm.rows, won: won, attempts: vm.guesses.count)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surfaceAlt))
                        .foregroundStyle(Theme.ink)
                }
                Button { dismiss(); onPrimary() } label: {
                    Text(primaryLabel).font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accent))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
        .background(Theme.bg.ignoresSafeArea())
    }

    private var winHeadline: String {
        switch vm.guesses.count {
        case 1: return "Genius!"
        case 2: return "Magnificent!"
        case 3: return "Impressive!"
        case 4: return "Splendid!"
        case 5: return "Great!"
        default: return "Phew!"
        }
    }
}
