import SwiftUI

/// Full detail for a single card: generated art, keywords, element, and both meanings.
struct CardDetailView: View {
    let card: TarotCard
    @State private var showReversed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CardArtView(card: card, reversed: showReversed)
                    .frame(maxWidth: 220)
                    .padding(.top, 8)
                    .accessibilityHidden(false)
                    .accessibilityLabel(cardAccessibilityLabel(card, reversed: showReversed))

                VStack(spacing: 6) {
                    Text(card.name)
                        .font(Theme.serif(28, .bold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                    HStack(spacing: 10) {
                        metaPill(card.arcana == .major ? "Major Arcana" : "\(card.suit?.rawValue ?? "") · \(card.rankName)")
                        metaPill("\(card.element.rawValue)", icon: card.element.symbol)
                    }
                }

                KeywordRow(keywords: card.keywords)
                    .frame(maxWidth: .infinity, alignment: .center)

                Picker("Orientation", selection: $showReversed) {
                    Text("Upright").tag(false)
                    Text("Reversed").tag(true)
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Orientation")

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeading(title: showReversed ? "Reversed" : "Upright",
                                   icon: showReversed ? "arrow.uturn.down" : "arrow.up")
                    Text(showReversed ? card.reversed : card.upright)
                        .font(.body)
                        .foregroundStyle(Theme.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardSurface()

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeading(title: "Both meanings", icon: "book")
                    meaningRow(label: "Upright", text: card.upright)
                    Divider().background(Theme.hairline)
                    meaningRow(label: "Reversed", text: card.reversed)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardSurface()
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func metaPill(_ text: String, icon: String? = nil) -> some View {
        HStack(spacing: 5) {
            if let icon { Image(systemName: icon).font(.caption2) }
            Text(text).font(.caption.weight(.semibold))
        }
        .foregroundStyle(Theme.accentDeep)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Capsule().fill(Theme.accentSoft))
    }

    private func meaningRow(label: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(Theme.inkFaint)
            Text(text).font(.callout).foregroundStyle(Theme.ink)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(text)")
    }
}
