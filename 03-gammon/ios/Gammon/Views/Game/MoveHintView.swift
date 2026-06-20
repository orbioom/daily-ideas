import SwiftUI

// MARK: - Move Hint View
// Shows a floating tooltip with info about selected piece and available moves.

struct MoveHintView: View {
    let game: BackgammonGame

    private var selectedPointNumber: Int? {
        guard let from = game.selectedFrom else { return nil }
        if from == -1 { return nil }  // bar
        return from + 1
    }

    private var isFromBar: Bool {
        game.selectedFrom == -1
    }

    private var destLabels: [String] {
        game.legalDests.map { dest in
            if dest == -2 { return "Bear Off" }
            return "Point \(dest + 1)"
        }.sorted()
    }

    var body: some View {
        if game.selectedFrom != nil {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "hand.point.up.left.fill")
                        .font(.caption)
                        .foregroundStyle(GammonTheme.accent)
                    Text(sourceLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GammonTheme.textPrimary)
                }

                if destLabels.isEmpty {
                    Text("No valid moves from here")
                        .font(.caption2)
                        .foregroundStyle(GammonTheme.textMuted)
                } else {
                    Text("Can move to: " + destLabels.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(GammonTheme.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(GammonTheme.surface)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(GammonTheme.accent.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }

    private var sourceLabel: String {
        if isFromBar {
            return "From Bar - tap an entry point"
        } else if let pt = selectedPointNumber {
            return "Point \(pt) selected"
        }
        return "Selected"
    }
}

// MARK: - Turn Indicator

struct TurnIndicatorView: View {
    let player: PieceColor
    let phase: BGPhase
    let isAIMode: Bool
    let isAIThinking: Bool

    private var phaseLabel: String {
        if isAIThinking { return "AI is thinking..." }
        switch phase {
        case .rolling: return "Tap 'Roll Dice'"
        case .moving: return "Select a piece to move"
        case .gameOver: return "Game Over"
        }
    }

    private var playerLabel: String {
        if isAIMode {
            return player == .white ? "Your Turn" : "AI's Turn"
        } else {
            return "\(player.displayName)'s Turn"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(player == .white ? GammonTheme.whitePiece : GammonTheme.blackPiece)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(GammonTheme.accent.opacity(0.6), lineWidth: 1))

            VStack(alignment: .leading, spacing: 1) {
                Text(playerLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(GammonTheme.textPrimary)
                Text(phaseLabel)
                    .font(.caption2)
                    .foregroundStyle(GammonTheme.textSecondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(GammonTheme.surface)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(GammonTheme.accentDark.opacity(0.5), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: player)
        .animation(.easeInOut(duration: 0.2), value: isAIThinking)
    }
}

#Preview {
    VStack(spacing: 20) {
        TurnIndicatorView(
            player: .white,
            phase: .rolling,
            isAIMode: true,
            isAIThinking: false
        )
        TurnIndicatorView(
            player: .black,
            phase: .moving,
            isAIMode: true,
            isAIThinking: true
        )
    }
    .padding()
    .background(GammonTheme.background)
}
