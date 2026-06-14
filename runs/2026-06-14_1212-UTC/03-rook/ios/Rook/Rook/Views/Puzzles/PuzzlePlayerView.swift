import SwiftUI
import SwiftData

/// Interactive solver for a single puzzle.
struct PuzzlePlayerView: View {
    let puzzle: Puzzle
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @StateObject private var vm: PuzzleViewModel
    @State private var selected: Square?
    @State private var legalTargets: [Square] = []
    @State private var pendingPromo: (from: Square, to: Square)?
    @State private var recorded = false

    init(puzzle: Puzzle) {
        self.puzzle = puzzle
        _vm = StateObject(wrappedValue: PuzzleViewModel(puzzle: puzzle))
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    BoardView(board: vm.board,
                              theme: settings.effectiveBoardTheme(isPro: isPro),
                              pieceStyle: settings.pieceStyle,
                              flipped: vm.puzzle.sideToMove == .black,
                              selectedSquare: selected,
                              legalTargets: legalTargets,
                              lastMove: vm.lastMove,
                              checkSquare: checkSquare,
                              showLegalDots: settings.showLegalDots,
                              onTapSquare: handleTap)
                    feedback
                    actions
                }
                .padding(16)
            }
        }
        .navigationTitle("Puzzle")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: promoBinding) {
            PromotionSheet(color: vm.sideToMove,
                           pieceStyle: settings.pieceStyle,
                           onPick: { piece in resolvePromotion(piece) },
                           onCancel: { pendingPromo = nil })
        }
        .onChange(of: vm.solved) { _, solved in
            if solved { recordResult() }
        }
    }

    private var checkSquare: Square? {
        if vm.board.kingInCheck(color: vm.board.sideToMove) {
            return vm.board.kingSquare(of: vm.board.sideToMove)
        }
        return nil
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TagPill(text: puzzle.theme.rawValue, symbol: puzzle.theme.symbol)
                TagPill(text: puzzle.difficultyLabel, symbol: "gauge.with.dots.needle.50percent",
                        tint: Theme.gold)
                Spacer()
            }
            Text(puzzle.prompt)
                .font(Theme.serif(20, .semibold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    // MARK: Feedback

    @ViewBuilder
    private var feedback: some View {
        if vm.solved {
            statusBanner(vm.revealedSolution ? "Solution shown" : "Solved!",
                         detail: vm.revealedSolution
                            ? "Here's the winning idea — try the next one."
                            : "Nicely done. That's the winning move.",
                         symbol: vm.revealedSolution ? "lightbulb.fill" : "checkmark.seal.fill",
                         tint: vm.revealedSolution ? Theme.gold : Theme.good)
        } else if vm.showWrong {
            statusBanner("Not quite",
                         detail: "That move doesn't win here. Take another look and try again.",
                         symbol: "arrow.counterclockwise",
                         tint: Theme.bad)
        } else if let hint = vm.hintSquare {
            statusBanner("Hint",
                         detail: "Look at the piece on \(hint.name).",
                         symbol: "lightbulb",
                         tint: Theme.gold)
        } else {
            statusBanner("\(vm.sideToMove == .white ? "White" : "Black") to move",
                         detail: "Find the move on the board.",
                         symbol: "hand.tap",
                         tint: Theme.accent)
        }
    }

    private func statusBanner(_ title: String, detail: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                Text(detail).font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(tint.opacity(0.12)))
        .accessibilityElement(children: .combine)
    }

    // MARK: Actions

    @ViewBuilder
    private var actions: some View {
        if vm.solved {
            VStack(spacing: 10) {
                PrimaryButton(title: "Back to puzzles", systemImage: "checkmark") { dismiss() }
                SecondaryButton(title: "Try again", systemImage: "arrow.counterclockwise") {
                    recorded = false
                    vm.reset()
                    clearSelection()
                }
            }
        } else {
            HStack(spacing: 10) {
                SecondaryButton(title: "Hint", systemImage: "lightbulb") {
                    vm.requestHint()
                    Haptics.tap(settings.hapticsEnabled)
                }
                SecondaryButton(title: "Show solution", systemImage: "eye") {
                    vm.revealSolution()
                    Haptics.warning(settings.hapticsEnabled)
                }
            }
        }
    }

    // MARK: Interaction

    private func handleTap(_ sq: Square) {
        guard !vm.solved else { return }
        vm.clearHint()
        if let from = selected {
            if legalTargets.contains(sq) {
                if vm.isPromotion(from: from, to: sq) {
                    pendingPromo = (from, sq)
                    clearSelection()
                    return
                }
                let ok = vm.submit(from: from, to: sq)
                feedbackHaptic(ok)
                clearSelection()
                return
            }
            selectIfOwnPiece(sq)
        } else {
            selectIfOwnPiece(sq)
        }
    }

    private func selectIfOwnPiece(_ sq: Square) {
        if let p = vm.board.piece(at: sq), p.color == vm.sideToMove {
            selected = sq
            legalTargets = vm.legalDestinations(from: sq).map { $0.to }
            Haptics.tap(settings.hapticsEnabled)
        } else {
            clearSelection()
        }
    }

    private func clearSelection() {
        selected = nil
        legalTargets = []
    }

    private var promoBinding: Binding<Bool> {
        Binding(get: { pendingPromo != nil }, set: { if !$0 { pendingPromo = nil } })
    }

    private func resolvePromotion(_ piece: PieceType) {
        guard let p = pendingPromo else { return }
        pendingPromo = nil
        let ok = vm.submit(from: p.from, to: p.to, promotion: piece)
        feedbackHaptic(ok)
        clearSelection()
    }

    private func feedbackHaptic(_ ok: Bool) {
        if ok { Haptics.success(settings.hapticsEnabled) }
        else { Haptics.error(settings.hapticsEnabled) }
    }

    // MARK: Persistence

    private func recordResult() {
        guard !recorded else { return }
        recorded = true
        let solvedClean = !vm.revealedSolution
        let result = PuzzleResult(puzzleID: puzzle.id,
                                  date: Date(),
                                  solved: solvedClean,
                                  hintsUsed: vm.hintsUsed,
                                  attempts: max(1, vm.attempts + 1))
        context.insert(result)
    }
}
