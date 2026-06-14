import SwiftUI

/// A short, honest "about" page.
struct AboutView: View {
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Theme.accentSoft)
                            .frame(width: 96, height: 96)
                        Image(systemName: "book")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                    }
                    .padding(.top, 24)

                    Text("Lexeme")
                        .font(Theme.serif(30, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("A beautiful, ad-free English vocabulary builder.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)

                    LexemeCard {
                        VStack(alignment: .leading, spacing: 12) {
                            aboutRow("text.book.closed", "A curated bank of \(WordBank.all.count) words across everyday, SAT, and GRE tiers.")
                            aboutRow("sun.max", "One thoughtfully chosen word every day.")
                            aboutRow("brain.head.profile", "Spaced repetition that resurfaces words right before you'd forget.")
                            aboutRow("gamecontroller", "Four quiz modes, from multiple choice to typed fill-in-the-blank.")
                            aboutRow("chart.line.uptrend.xyaxis", "Honest progress charts and milestones.")
                        }
                    }
                    .padding(.horizontal, 18)

                    Text("Definitions and examples are curated for clarity, not exhaustiveness. Lexeme is a study companion, not a dictionary of record.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkFaint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 28)
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func aboutRow(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
