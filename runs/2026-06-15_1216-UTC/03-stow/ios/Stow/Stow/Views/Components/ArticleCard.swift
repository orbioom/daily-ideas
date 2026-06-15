import SwiftUI

/// A reading-list card: title, meta, excerpt, tags, progress.
struct ArticleCard: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(article.siteName.isEmpty ? "Saved" : article.siteName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .lineLimit(1)
                Text("·")
                    .foregroundStyle(Theme.inkFaint)
                Text("\(article.estMinutes) min read")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
                Spacer(minLength: 4)
                if article.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                }
            }

            Text(article.title)
                .font(Theme.serif(19, .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            if !article.excerpt.isEmpty {
                Text(article.excerpt)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !article.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(article.tags.sorted { $0.name < $1.name }) { tag in
                            TagBadge(name: tag.name, colorHex: tag.colorHex)
                        }
                    }
                }
            }

            if article.readingProgress > 0.001 {
                ProgressBar(value: article.readingProgress)
                    .frame(height: 4)
                    .padding(.top, 2)
                    .accessibilityLabel("Reading progress \(Int(article.readingProgress * 100)) percent")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [article.title]
        if !article.siteName.isEmpty { parts.append("from \(article.siteName)") }
        parts.append("\(article.estMinutes) minute read")
        if article.isFavorite { parts.append("Favorite") }
        if article.readingProgress > 0.001 {
            parts.append("\(Int(article.readingProgress * 100)) percent read")
        }
        return parts.joined(separator: ", ")
    }
}

/// A simple themed progress bar.
struct ProgressBar: View {
    var value: Double // 0...1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.hairline)
                Capsule()
                    .fill(Theme.accent)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
    }
}
