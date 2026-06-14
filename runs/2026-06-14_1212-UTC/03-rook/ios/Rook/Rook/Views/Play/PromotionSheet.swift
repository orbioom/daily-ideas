import SwiftUI

/// Promotion picker presented when a pawn reaches the last rank.
struct PromotionSheet: View {
    let color: PieceColor
    var pieceStyle: PieceStyle = .classic
    let onPick: (PieceType) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Text("Promote pawn")
                .font(Theme.serif(22, .bold))
                .foregroundStyle(Theme.ink)
                .padding(.top, 8)
            Text("Choose the piece your pawn becomes.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)

            HStack(spacing: 14) {
                ForEach(PieceType.promotionChoices, id: \.self) { type in
                    Button {
                        onPick(type)
                    } label: {
                        VStack(spacing: 6) {
                            PieceGlyph(piece: Piece(color: color, type: type),
                                       size: 46, style: pieceStyle)
                                .frame(height: 52)
                            Text(name(type))
                                .font(Theme.rounded(12, .medium))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.surfaceAlt))
                    }
                    .accessibilityLabel("Promote to \(name(type))")
                }
            }

            Button("Cancel") { onCancel() }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
                .padding(.top, 2)
        }
        .padding(20)
        .presentationDetents([.height(240)])
        .background(Theme.bg.ignoresSafeArea())
    }

    private func name(_ t: PieceType) -> String {
        switch t {
        case .queen: return "Queen"
        case .rook: return "Rook"
        case .bishop: return "Bishop"
        case .knight: return "Knight"
        default: return ""
        }
    }
}
