import SwiftUI

/// Detail page for a piece-movement or tactics lesson, with a live board diagram.
struct LearnDetailView: View {
    let route: LearnRoute
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    if let piece = pieceLesson {
                        diagram(fen: piece.fen, highlights: piece.highlights, flipped: false)
                        textCard(title: piece.name, body: piece.summary)
                        legendCard
                    } else if let tactic = tacticLesson {
                        diagram(fen: tactic.fen, highlights: tactic.highlights, flipped: tactic.flipped)
                        textCard(title: tactic.name, body: tactic.summary)
                        legendCard
                    } else {
                        EmptyStateView(symbol: "book",
                                       title: "Lesson unavailable",
                                       message: "This lesson could not be loaded. Go back and pick another.")
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var pieceLesson: LearnContent.PieceLesson? {
        if case .piece(let type) = route {
            return LearnContent.pieces.first { $0.id == type }
        }
        return nil
    }

    private var tacticLesson: LearnContent.TacticLesson? {
        if case .tactic(let id) = route {
            return LearnContent.tactics.first { $0.id == id }
        }
        return nil
    }

    private var title: String {
        pieceLesson?.name ?? tacticLesson?.name ?? "Lesson"
    }

    private func diagram(fen: String, highlights: [String], flipped: Bool) -> some View {
        let board = Board(fen: fen) ?? Board.standard
        let squares = highlights.compactMap { Square(name: $0) }
        return BoardView(board: board,
                         theme: settings.effectiveBoardTheme(isPro: isPro),
                         pieceStyle: settings.pieceStyle,
                         flipped: flipped,
                         legalTargets: squares,
                         showLegalDots: true,
                         onTapSquare: nil)
            .padding(2)
    }

    private func textCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.serif(22, .bold)).foregroundStyle(Theme.ink)
            Text(body)
                .font(Theme.rounded(16)).foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    private var legendCard: some View {
        HStack(spacing: 10) {
            Circle().fill(Color.black.opacity(0.28)).frame(width: 14, height: 14)
            Text("Marked squares show the highlighted idea — destinations or key squares.")
                .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surfaceAlt))
    }
}
