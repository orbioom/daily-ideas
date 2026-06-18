import SwiftUI

/// Generous photo card for the timeline / memories feeds.
struct MomentCard: View {
    let moment: Moment

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MomentImageView(filename: moment.imageFilename, pointSize: 360, cornerRadius: 0)
                .aspectRatio(4.0 / 3.0, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(alignment: .topTrailing) {
                    if moment.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(7)
                            .background(.black.opacity(0.28), in: Circle())
                            .padding(10)
                            .accessibilityHidden(true)
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    MoodPill(mood: moment.mood)
                        .padding(10)
                }

            VStack(alignment: .leading, spacing: 7) {
                Text(Self.dateFormatter.string(from: moment.displayDate))
                    .font(Theme.rounded(12, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .textCase(.uppercase)

                if !moment.title.isEmpty {
                    Text(moment.title)
                        .font(Theme.rounded(20, .bold))
                        .foregroundStyle(Theme.ink)
                }

                if !moment.caption.isEmpty {
                    Text(moment.caption)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.ink.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !moment.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(moment.tags, id: \.self) { tag in
                                TagChip(tag: tag)
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(14)
        }
        .cardSurface()
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        var parts: [String] = [Self.dateFormatter.string(from: moment.displayDate)]
        if !moment.title.isEmpty { parts.append(moment.title) }
        if !moment.caption.isEmpty { parts.append(moment.caption) }
        parts.append("Mood \(moment.mood.label)")
        if moment.isFavorite { parts.append("Favorite") }
        return parts.joined(separator: ". ")
    }
}
