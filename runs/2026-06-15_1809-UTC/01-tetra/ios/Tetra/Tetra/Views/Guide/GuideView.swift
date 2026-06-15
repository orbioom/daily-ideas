import SwiftUI

struct GuideView: View {
    private let tileLegend = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096]

    private let howTo: [(symbol: String, title: String, body: String)] = [
        ("hand.draw.fill", "Swipe to slide",
         "Swipe up, down, left, or right. Every tile slides as far as it can in that direction until it hits a wall or another tile."),
        ("arrow.triangle.merge", "Merge equal tiles",
         "When two tiles with the same number collide, they merge into one tile worth double. 2 + 2 makes 4, 4 + 4 makes 8, and so on."),
        ("star.fill", "Reach 2048",
         "Each swipe also drops a new 2 (or, rarely, a 4) onto the board. Keep merging to build a 2048 tile — then keep going for an even bigger one."),
        ("flag.checkered", "Don't fill up",
         "The game ends when the board is full and no neighbouring tiles match. Plan your swipes so you always leave room to merge.")
    ]

    private let tips: [(symbol: String, title: String, body: String)] = [
        ("arrow.down.to.line", "Pick a corner",
         "Keep your biggest tile anchored in one corner and build a descending chain toward it. Most strong players favour a single corner all game."),
        ("arrow.left.arrow.right", "Use two directions",
         "Try to play mostly along two axes (for example down and left) so your big tile never gets pulled away from its corner."),
        ("eye.fill", "Think one swipe ahead",
         "Before you swipe, check what new gaps it opens. Avoid moves that scatter your small tiles across the board."),
        ("arrow.uturn.backward", "Undo a slip",
         "Made a swipe you regret? Undo steps it back. Free games include a few undos each; Tetra Pro makes them unlimited.")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        howToCard
                        tipsCard
                        legendCard
                        goalNote
                    }
                    .padding(18)
                }
            }
            .navigationTitle("How to play")
        }
    }

    private var howToCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "The basics", systemImage: "square.grid.2x2.fill")
            ForEach(Array(howTo.enumerated()), id: \.offset) { _, item in
                guideRow(item)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Strategy tips", systemImage: "lightbulb.fill")
            ForEach(Array(tips.enumerated()), id: \.offset) { _, item in
                guideRow(item)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private func guideRow(_ item: (symbol: String, title: String, body: String)) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.accentSoft)
                    .frame(width: 38, height: 38)
                Image(systemName: item.symbol)
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.ink)
                Text(item.body)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var legendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Tile colors", systemImage: "paintpalette.fill")
            Text("Each value has its own hue, so you can read the board at a glance.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkFaint)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 10)], spacing: 10) {
                ForEach(tileLegend, id: \.self) { value in
                    let colors = Theme.tileColors(forValue: value)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(colors.fill)
                        .frame(height: 56)
                        .overlay(
                            Text("\(value)")
                                .font(Theme.rounded(value >= 1024 ? 16 : 19, .heavy))
                                .foregroundStyle(colors.ink)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .padding(2)
                        )
                        .accessibilityLabel("Tile \(value)")
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var goalNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "target")
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("The classic goal is the 2048 tile, but the board keeps going. The 4096 tile — and beyond — is where the real bragging rights live.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(fill: Theme.surfaceAlt)
        .accessibilityElement(children: .combine)
    }
}
