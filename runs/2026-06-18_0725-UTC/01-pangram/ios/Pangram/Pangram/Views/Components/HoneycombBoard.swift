import SwiftUI

/// The 7-tile honeycomb: a center tile surrounded by six outer tiles.
struct HoneycombBoard: View {
    let center: Character
    let outer: [Character]
    let colorBlindSafe: Bool
    let reduceMotion: Bool
    let onTap: (Character) -> Void

    /// Tile size relative to the available width.
    private let tile: CGFloat = 92

    var body: some View {
        // Six outer positions around the center, hex-grid offsets.
        let dx = tile * 0.86
        let dy = tile * 0.75
        let positions: [CGSize] = [
            CGSize(width: 0, height: -dy * 2),
            CGSize(width: dx, height: -dy),
            CGSize(width: dx, height: dy),
            CGSize(width: 0, height: dy * 2),
            CGSize(width: -dx, height: dy),
            CGSize(width: -dx, height: -dy)
        ]

        ZStack {
            ForEach(Array(outer.prefix(6).enumerated()), id: \.offset) { idx, letter in
                let offset = positions[min(idx, positions.count - 1)]
                HexTile(
                    letter: letter,
                    isCenter: false,
                    colorBlindSafe: colorBlindSafe,
                    reduceMotion: reduceMotion,
                    action: { onTap(letter) }
                )
                .frame(width: tile, height: tile)
                .offset(offset)
            }
            HexTile(
                letter: center,
                isCenter: true,
                colorBlindSafe: colorBlindSafe,
                reduceMotion: reduceMotion,
                action: { onTap(center) }
            )
            .frame(width: tile, height: tile)
        }
        .frame(width: tile * 3, height: tile * 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Honeycomb. Center letter \(String(center).uppercased()).")
    }
}
