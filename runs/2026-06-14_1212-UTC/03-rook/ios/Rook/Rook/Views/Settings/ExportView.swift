import SwiftUI
import SwiftData

/// Export the most recent game as readable, shareable text (PGN-ish move list).
struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SavedGame.updatedAt, order: .reverse) private var games: [SavedGame]
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let game = games.first, !game.moveList.isEmpty {
                        Text("Your latest game")
                            .font(Theme.serif(20, .bold)).foregroundStyle(Theme.ink)
                        Text(exportText(game))
                            .font(Theme.rounded(14).monospaced())
                            .foregroundStyle(Theme.ink)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))

                        Button {
                            UIPasteboard.general.string = exportText(game)
                            copied = true
                        } label: {
                            Label(copied ? "Copied" : "Copy to clipboard",
                                  systemImage: copied ? "checkmark" : "doc.on.doc")
                                .font(Theme.rounded(16, .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(copied ? Theme.good : Theme.accent))
                        }

                        if let item = shareItem(game) {
                            ShareLink(item: item) {
                                Label("Share…", systemImage: "square.and.arrow.up")
                                    .font(Theme.rounded(16, .semibold))
                                    .foregroundStyle(Theme.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(Theme.accent.opacity(0.5), lineWidth: 1.5))
                            }
                        }
                    } else {
                        EmptyStateView(symbol: "square.and.arrow.up",
                                       title: "No game to export",
                                       message: "Play some moves on the Play tab, then come back to export the game as text.")
                            .padding(.top, 40)
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }

    private func shareItem(_ game: SavedGame) -> String? {
        let text = exportText(game)
        return text.isEmpty ? nil : text
    }

    private func exportText(_ game: SavedGame) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        var lines: [String] = []
        lines.append("Rook game — \(df.string(from: game.createdAt))")
        lines.append("Opponent: \(game.vsComputer ? "Computer (\(game.aiLevel.label))" : "Two players")")
        lines.append("You played: \(game.humanSide.label)")
        lines.append("Result: \(game.result.label)")
        lines.append("")

        let moves = game.moveList
        var body = ""
        var i = 0
        var number = 1
        while i < moves.count {
            let white = moves[i]
            let black = (i + 1 < moves.count) ? moves[i + 1] : ""
            body += "\(number). \(white) \(black)  "
            i += 2
            number += 1
        }
        lines.append(body.trimmingCharacters(in: .whitespaces))
        return lines.joined(separator: "\n")
    }
}
