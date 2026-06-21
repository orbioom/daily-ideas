import SwiftUI

struct TileView: View {
    let tile: Int
    let total: Int
    let size: CGFloat
    let theme: SlideArtTheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.tileColor(tile: tile, total: total))
            RoundedRectangle(cornerRadius: 8)
                .stroke(SlideTheme.border, lineWidth: 1)
            Text("\(tile)")
                .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}
