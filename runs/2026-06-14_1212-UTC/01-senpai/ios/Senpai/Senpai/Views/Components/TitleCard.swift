import SwiftUI

/// A gradient cover card for the Library grid.
struct TitleCard: View {
    let title: Title
    var hideScore: Bool = false
    var intensity: AccentIntensity = .standard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                CoverView(hue: title.coverHue,
                          kind: title.kind,
                          initials: title.name.coverInitials,
                          intensity: intensity,
                          cornerRadius: 16)
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)

                if title.favorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Circle().fill(Theme.accent.opacity(0.85)))
                        .padding(8)
                        .accessibilityLabel("Favorite")
                }
            }

            Text(title.name)
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            ProgressBar(fraction: title.progressFraction)

            HStack(spacing: 6) {
                Text(title.progressLabel)
                    .font(Theme.rounded(11, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .monospacedDigit()
                Spacer(minLength: 2)
                ScoreChip(score: title.score, hidden: hideScore)
            }

            StatusPill(status: title.status, kind: title.kind)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title.name), \(title.statusLabel), \(title.progressLabel) \(title.kind.unitNounPlural)")
    }
}
