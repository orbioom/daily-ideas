import SwiftUI
import SwiftData

/// Full reference for a single card: both meanings, keywords, element, and which
/// of the user's saved readings this card has appeared in.
struct CardDetailView: View {
    let card: TarotCard

    @Query private var readings: [Reading]

    /// Saved readings that include this card, most recent first.
    private var appearances: [Reading] {
        readings
            .filter { r in r.cards.contains { $0.cardID == card.id } }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CardFace(card: card, reversed: false, size: .large)

                HStack(spacing: 12) {
                    metaTile(label: "Arcana", value: card.arcana == .major ? "Major" : (card.suit?.title ?? "Minor"))
                    metaTile(label: "Element", value: card.element)
                    metaTile(label: card.arcana == .major ? "Number" : "Rank", value: "\(card.number)")
                }

                meaningSection(title: "Upright", keywords: card.upright, meaning: card.uprightMeaning, tint: Brand.magic)
                meaningSection(title: "Reversed", keywords: card.reversed, meaning: card.reversedMeaning, tint: Brand.warn)

                appearancesSection
            }
            .padding(20)
        }
        .background(Brand.pageBackground)
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func metaTile(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Brand.mono(15, weight: .semibold))
                .foregroundStyle(Brand.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label.uppercased())
                .font(Brand.mono(10, weight: .medium))
                .tracking(1)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func meaningSection(title: String, keywords: [String], meaning: String, tint: Color) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: title == "Upright" ? "arrow.up" : "arrow.uturn.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(tint)
                        .accessibilityHidden(true)
                    SectionTitle(text: title)
                }
                KeywordChips(keywords: keywords, tint: tint)
                Text(meaning)
                    .font(.body)
                    .foregroundStyle(Brand.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var appearancesSection: some View {
        SectionTitle(text: "In your readings")
        if appearances.isEmpty {
            GlassCard {
                Text("This card hasn't appeared in your saved readings yet.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
            }
        } else {
            ForEach(appearances) { reading in
                NavigationLink {
                    ReadingDetailView(reading: reading)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(reading.spreadName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Brand.text)
                            Text(reading.date.formatted(date: .abbreviated, time: .omitted))
                                .font(Brand.mono(12))
                                .foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        if reading.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundStyle(Brand.warn)
                                .accessibilityLabel("Favorite")
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Brand.text3)
                            .accessibilityHidden(true)
                    }
                    .glassCard()
                }
                .buttonStyle(.plain)
            }
        }
    }
}
