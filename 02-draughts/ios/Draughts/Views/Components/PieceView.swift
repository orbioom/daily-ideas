import SwiftUI

struct PieceView: View {
    let piece: Piece
    let size: CGFloat

    var body: some View {
        ZStack {
            // Shadow / base circle
            Circle()
                .fill(shadowColor)
                .frame(width: size, height: size)
                .offset(y: size * 0.06)

            // Main piece body
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [highlightColor, baseColor]),
                        center: .init(x: 0.38, y: 0.32),
                        startRadius: 0,
                        endRadius: size * 0.55
                    )
                )
                .frame(width: size, height: size)

            // King indicator: an inner ring
            if piece.type == .king {
                Circle()
                    .strokeBorder(DraughtsTheme.gold, lineWidth: size * 0.07)
                    .frame(width: size * 0.58, height: size * 0.58)

                Image(systemName: "crown.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.30, height: size * 0.30)
                    .foregroundColor(DraughtsTheme.gold)
            }
        }
        .frame(width: size, height: size)
    }

    private var baseColor: Color {
        piece.player == .red ? DraughtsTheme.redPiece : DraughtsTheme.blackPiece
    }

    private var highlightColor: Color {
        piece.player == .red
            ? Color(red: 1.0, green: 0.40, blue: 0.35)
            : Color(red: 0.22, green: 0.22, blue: 0.22)
    }

    private var shadowColor: Color {
        piece.player == .red
            ? Color(red: 0.50, green: 0.05, blue: 0.03).opacity(0.70)
            : Color(red: 0.0, green: 0.0, blue: 0.0).opacity(0.70)
    }
}

#Preview {
    HStack(spacing: 16) {
        PieceView(piece: Piece(player: .red, type: .man), size: 56)
        PieceView(piece: Piece(player: .red, type: .king), size: 56)
        PieceView(piece: Piece(player: .black, type: .man), size: 56)
        PieceView(piece: Piece(player: .black, type: .king), size: 56)
    }
    .padding()
    .background(DraughtsTheme.background)
}
