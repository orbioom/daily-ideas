import SwiftUI

struct DiscView: View {
    let piece: Piece
    let highlighted: Bool

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .fill(piece == .black ? Color(white: 0.10) : Color(white: 0.95))
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
                if piece == .white {
                    Circle()
                        .stroke(Color(white: 0.70), lineWidth: 1)
                        .padding(2)
                }
                if highlighted {
                    Circle()
                        .stroke(IvoryTheme.accent, lineWidth: 2)
                }
            }
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}
