import SwiftUI
import SwiftData

/// The shared board + keyboard used by both Daily and Practice. The parent
/// supplies the LexicGame; `onNewGame` (when non-nil) enables "Play again".
struct GameBoardView: View {
    @State var vm: LexicGame
    var onNewGame: (() -> Void)?

    @State private var showResult = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 4)
            grid
                .padding(.horizontal, 28)
            Spacer(minLength: 4)
            KeyboardView(states: vm.keyboard,
                         onKey: { vm.type($0) },
                         onEnter: { vm.submit() },
                         onDelete: { vm.backspace() })
                .padding(.bottom, 8)
        }
        .overlay(alignment: .top) { toast }
        .overlay { if showResult { resultCard } }
        .onChange(of: vm.justFinished) { _, done in
            if done { withAnimation(Brand.ease()) { showResult = true } }
        }
        .onAppear { if vm.isFinished { showResult = true } }
    }

    private var grid: some View {
        VStack(spacing: 6) {
            ForEach(0..<WordEngine.maxGuesses, id: \.self) { row in
                rowView(row)
            }
        }
    }

    @ViewBuilder
    private func rowView(_ row: Int) -> some View {
        if row < vm.guesses.count {
            let guess = vm.guesses[row]
            GuessRow(letters: Array(guess).map { Optional($0) },
                     states: vm.states(for: guess),
                     reveal: true)
        } else if row == vm.guesses.count && !vm.isFinished {
            let typed = Array(vm.current)
            GuessRow(letters: (0..<5).map { typed[safe: $0] },
                     states: Array(repeating: .empty, count: 5),
                     shake: vm.shakeRow)
        } else {
            GuessRow(letters: Array(repeating: nil, count: 5),
                     states: Array(repeating: .empty, count: 5))
        }
    }

    @ViewBuilder
    private var toast: some View {
        if let t = vm.toast {
            Text(t)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Brand.text.opacity(0.92), in: Capsule())
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(Brand.ease(0.25), value: vm.toast)
        }
    }

    private var resultCard: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
                .onTapGesture { withAnimation { showResult = false } }
            VStack(spacing: 18) {
                Image(systemName: vm.state == .won ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(vm.state == .won ? Brand.magic : Brand.danger)
                    .accessibilityHidden(true)
                Text(vm.state == .won ? resultPraise : "So close")
                    .font(.title2.bold()).foregroundStyle(Brand.text)
                if vm.state == .lost {
                    Text("The word was")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                    Text(vm.answer.uppercased())
                        .font(.title3.weight(.bold)).foregroundStyle(LetterState.correct.tint)
                }

                miniGrid

                VStack(spacing: 10) {
                    ShareLink(item: vm.shareText()) {
                        Label("Share result", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(InkButtonStyle())

                    if let onNewGame {
                        Button { withAnimation { showResult = false }; onNewGame() } label: {
                            Label("Play again", systemImage: "arrow.clockwise").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                    Button("Close") { withAnimation { showResult = false } }
                        .font(.subheadline).foregroundStyle(Brand.text2)
                }
            }
            .padding(26)
            .frame(maxWidth: 340)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
            .padding(.horizontal, 28)
        }
        .transition(.opacity)
    }

    private var miniGrid: some View {
        VStack(spacing: 3) {
            ForEach(vm.guesses.indices, id: \.self) { i in
                HStack(spacing: 3) {
                    ForEach(vm.states(for: vm.guesses[i]).indices, id: \.self) { j in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(vm.states(for: vm.guesses[i])[j].tint)
                            .frame(width: 18, height: 18)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    private var resultPraise: String {
        switch vm.guesses.count {
        case 1: return "Incredible!"
        case 2: return "Magnificent!"
        case 3: return "Impressive!"
        case 4: return "Solid!"
        default: return "Got it!"
        }
    }
}
