import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Tip: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let body: String
    }

    private let tips: [Tip] = [
        Tip(symbol: "hand.tap.fill", title: "Swap to match",
            body: "Swap two adjacent gems to line up three or more of the same kind in a row or column. A swap that makes no match simply slides back."),
        Tip(symbol: "eye.fill", title: "Read by shape",
            body: "Every gem color also has its own symbol, so you can play comfortably even with color-vision differences."),
        Tip(symbol: "bolt.fill", title: "Striped gems",
            body: "Match four gems to create a striped gem. Match it later to blast its entire row and column."),
        Tip(symbol: "burst.fill", title: "Color bombs",
            body: "Match five in a line to forge a color bomb. Swap or match it to clear every gem of one color at once."),
        Tip(symbol: "flame.fill", title: "Chain cascades",
            body: "When gems fall and form new matches, cascades chain up multipliers (×2, ×3…). Set up big drops for huge scores."),
        Tip(symbol: "arrow.triangle.2.circlepath", title: "Always a move",
            body: "If no moves remain, the board reshuffles automatically — you'll never get stuck.")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(tips) { tip in
                            GlintCard {
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: tip.symbol)
                                        .font(.system(size: 22))
                                        .foregroundStyle(Theme.accent)
                                        .frame(width: 32)
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(tip.title)
                                            .font(Theme.rounded(17, .bold))
                                            .foregroundStyle(Theme.ink)
                                        Text(tip.body)
                                            .font(Theme.rounded(14))
                                            .foregroundStyle(Theme.inkSoft)
                                    }
                                }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
