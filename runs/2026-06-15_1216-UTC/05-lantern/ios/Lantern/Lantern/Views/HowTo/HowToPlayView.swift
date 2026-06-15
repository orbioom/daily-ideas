import SwiftUI

/// Rules + the free-tile explanation. Reachable from Home and Settings.
struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    section(
                        icon: "target",
                        title: "The goal",
                        body: "Clear every tile from the board by removing matching pairs. Empty the board to win."
                    )
                    freeTileSection
                    section(
                        icon: "rectangle.on.rectangle",
                        title: "Matching",
                        body: "Two free tiles match when they show the same face. Flowers match any other Flower, and Seasons match any other Season — even if their pictures differ."
                    )
                    section(
                        icon: "lightbulb",
                        title: "Hints, undo & shuffle",
                        body: "Use a hint to highlight a matching pair, undo to take back a move, and shuffle to rearrange the remaining tiles if you get stuck. Every board is generated so it can always be finished."
                    )
                    section(
                        icon: "calendar",
                        title: "Daily Challenge",
                        body: "Each day has one shared board — the same puzzle for everyone. Solve it to build your streak."
                    )
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var freeTileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("What makes a tile free", systemImage: "hand.tap")
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)

            Text("You can only remove tiles that are free. A tile is free when:")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)

            ruleRow("square.stack.3d.up.slash", "Nothing is stacked on top of it.")
            ruleRow("arrow.left.and.right", "Its left or right edge is open (no tile beside it on that side).")

            Text("If a tile is boxed in on both sides, or covered from above, it's blocked until you clear its neighbors. Turn on \u{201C}Highlight free tiles\u{201D} in Settings to see free tiles at a glance.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkFaint)
        }
        .cardSurface()
        .accessibilityElement(children: .combine)
    }

    private func ruleRow(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16)).foregroundStyle(Theme.accent).frame(width: 24)
            Text(text).font(Theme.rounded(15)).foregroundStyle(Theme.ink)
            Spacer(minLength: 0)
        }
    }

    private func section(icon: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)
            Text(body)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(body)")
    }
}
