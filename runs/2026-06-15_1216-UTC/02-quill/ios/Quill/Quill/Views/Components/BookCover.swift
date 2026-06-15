import SwiftUI

/// A notebook rendered as a colored book cover with a spine, title, and meta.
struct BookCover: View {
    let title: String
    let colorHex: String
    let pageCount: Int
    let isFavorite: Bool
    let template: PaperTemplate

    private var cover: Color { Color(hexString: colorHex) }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [cover, cover.opacity(0.82)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(alignment: .leading) {
                        // Spine
                        Rectangle()
                            .fill(Color.black.opacity(0.18))
                            .frame(width: 10)
                            .clipShape(
                                .rect(topLeadingRadius: 10, bottomLeadingRadius: 10)
                            )
                    }
                    .overlay(alignment: .topTrailing) {
                        if isFavorite {
                            Image(systemName: "star.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white.opacity(0.95))
                                .padding(8)
                                .accessibilityHidden(true)
                        }
                    }
                    .overlay {
                        // Subtle template hint on the cover.
                        Image(systemName: template.systemImage)
                            .font(.system(size: 40, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.16))
                            .accessibilityHidden(true)
                    }

                Text(title)
                    .font(Theme.serif(17, .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 18)
                    .padding(.trailing, 12)
                    .padding(.bottom, 16)
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            }
            .aspectRatio(0.76, contentMode: .fit)
            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)

            HStack(spacing: 4) {
                Image(systemName: "doc")
                    .font(.system(size: 11))
                    .accessibilityHidden(true)
                Text("\(pageCount) page\(pageCount == 1 ? "" : "s")")
                    .font(Theme.rounded(12))
            }
            .foregroundStyle(Theme.inkSoft)
            .padding(.top, 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(pageCount) page\(pageCount == 1 ? "" : "s")\(isFavorite ? ", favorite" : "")")
        .accessibilityAddTraits(.isButton)
    }
}
