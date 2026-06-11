import SwiftUI

struct MediaCardView: View {
    let entry: MediaEntry
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.bgSecondary)
                        .aspectRatio(2/3, contentMode: .fit)

                    Text(entry.posterEmoji)
                        .font(.system(size: 56))
                        .accessibilityHidden(true)
                }

                Image(systemName: entry.status.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.statusColor(entry.status))
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
                    .padding(6)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text(String(entry.year))
                        .font(.caption2)
                        .foregroundStyle(Theme.silver)

                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(Theme.silver)

                    Text(entry.genre.rawValue)
                        .font(.caption2)
                        .foregroundStyle(Theme.genreColor(entry.genre))
                }

                if entry.mediaType == .show && entry.status == .watching {
                    ProgressView(value: entry.watchProgress)
                        .tint(Theme.gold)
                        .scaleEffect(y: 0.7)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title), \(entry.year), \(entry.genre.rawValue), \(entry.status.rawValue)")
    }
}
