import SwiftUI

struct TileView: View {
    let leftPip: Int
    let rightPip: Int
    let isDouble: Bool
    let isSelected: Bool
    let isHighlighted: Bool   // open-end indicator on board
    let isFaceDown: Bool
    let tileStyle: DominoTheme.TileStyle

    // Dimensions
    let shortSide: CGFloat
    let longSide: CGFloat

    private var tileColor: Color { tileStyle.tileColor }
    private var pip: Color { tileStyle.pipColor }
    private var divider: Color { tileStyle.dividerColor }

    var body: some View {
        if isDouble {
            doubleLayout
        } else {
            horizontalLayout
        }
    }

    // Non-double: wide (longSide × shortSide)
    private var horizontalLayout: some View {
        ZStack {
            if isFaceDown {
                faceDownBody(width: longSide, height: shortSide)
            } else {
                RoundedRectangle(cornerRadius: DominoTheme.tileCornerRadius)
                    .fill(tileColor)
                    .frame(width: longSide, height: shortSide)
                    .overlay {
                        HStack(spacing: 0) {
                            PipView(value: leftPip, pipColor: pip, size: shortSide * 0.75)
                                .frame(width: longSide / 2, height: shortSide)
                            Rectangle()
                                .fill(divider)
                                .frame(width: 1, height: shortSide * 0.6)
                            PipView(value: rightPip, pipColor: pip, size: shortSide * 0.75)
                                .frame(width: longSide / 2, height: shortSide)
                        }
                    }
                    .overlay {
                        if isHighlighted {
                            RoundedRectangle(cornerRadius: DominoTheme.tileCornerRadius)
                                .stroke(DominoTheme.chainHighlight, lineWidth: 2.5)
                        }
                        if isSelected {
                            RoundedRectangle(cornerRadius: DominoTheme.tileCornerRadius)
                                .stroke(DominoTheme.gold, lineWidth: 2.5)
                        }
                    }
            }
        }
        .dominoTileShadow()
        .accessibilityLabel("\(leftPip) \(rightPip) domino tile")
    }

    // Double: tall (shortSide × longSide) — rotated 90°
    private var doubleLayout: some View {
        ZStack {
            if isFaceDown {
                faceDownBody(width: shortSide, height: longSide)
            } else {
                RoundedRectangle(cornerRadius: DominoTheme.tileCornerRadius)
                    .fill(tileColor)
                    .frame(width: shortSide, height: longSide)
                    .overlay {
                        VStack(spacing: 0) {
                            PipView(value: leftPip, pipColor: pip, size: shortSide * 0.75)
                                .frame(width: shortSide, height: longSide / 2)
                            Rectangle()
                                .fill(divider)
                                .frame(width: shortSide * 0.6, height: 1)
                            PipView(value: rightPip, pipColor: pip, size: shortSide * 0.75)
                                .frame(width: shortSide, height: longSide / 2)
                        }
                    }
                    .overlay {
                        if isHighlighted {
                            RoundedRectangle(cornerRadius: DominoTheme.tileCornerRadius)
                                .stroke(DominoTheme.chainHighlight, lineWidth: 2.5)
                        }
                        if isSelected {
                            RoundedRectangle(cornerRadius: DominoTheme.tileCornerRadius)
                                .stroke(DominoTheme.gold, lineWidth: 2.5)
                        }
                    }
            }
        }
        .dominoTileShadow()
        .accessibilityLabel("Double \(leftPip) domino tile")
    }

    private func faceDownBody(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: DominoTheme.tileCornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        DominoTheme.mahogany.opacity(0.8),
                        DominoTheme.mahoganyDark
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: width, height: height)
            .overlay {
                RoundedRectangle(cornerRadius: DominoTheme.tileCornerRadius)
                    .stroke(DominoTheme.gold.opacity(0.5), lineWidth: 1)
            }
    }
}

// MARK: - Convenience inits

extension TileView {
    // For board chain tiles
    init(placed: DominoEngine.PlacedTile, isHighlighted: Bool = false, tileStyle: DominoTheme.TileStyle = .classic) {
        self.leftPip = placed.leftPip
        self.rightPip = placed.rightPip
        self.isDouble = placed.isDouble
        self.isSelected = false
        self.isHighlighted = isHighlighted
        self.isFaceDown = false
        self.tileStyle = tileStyle
        self.shortSide = DominoTheme.tileShortSide
        self.longSide = DominoTheme.tileLongSide
    }

    // For player hand tiles
    init(tile: DominoTile, isSelected: Bool = false, isFaceDown: Bool = false, tileStyle: DominoTheme.TileStyle = .classic) {
        self.leftPip = tile.a
        self.rightPip = tile.b
        self.isDouble = tile.isDouble
        self.isSelected = isSelected
        self.isHighlighted = false
        self.isFaceDown = isFaceDown
        self.tileStyle = tileStyle
        self.shortSide = DominoTheme.tileShortSide
        self.longSide = DominoTheme.tileLongSide
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 8) {
            TileView(tile: DominoTile(a: 3, b: 5), tileStyle: .classic)
            TileView(tile: DominoTile(a: 6, b: 6), tileStyle: .classic)
            TileView(tile: DominoTile(a: 0, b: 0), tileStyle: .classic)
        }
        HStack(spacing: 8) {
            TileView(tile: DominoTile(a: 1, b: 4), isSelected: true, tileStyle: .classic)
            TileView(tile: DominoTile(a: 2, b: 6), isFaceDown: true, tileStyle: .classic)
        }
    }
    .padding()
    .background(DominoTheme.mahogany)
}
