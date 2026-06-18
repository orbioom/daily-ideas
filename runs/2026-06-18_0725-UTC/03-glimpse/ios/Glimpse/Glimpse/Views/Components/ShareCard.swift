import SwiftUI

/// A self-contained, branded card rendered to an image via ImageRenderer for
/// sharing. Loads its photo synchronously (full image) so the render is
/// complete; falls back to the hero gradient if the file is missing.
struct ShareCard: View {
    let moment: Moment

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f
    }()

    private var loadedImage: UIImage? {
        ImageStore.shared.loadFull(moment.imageFilename)
            ?? ImageStore.shared.loadThumbnail(moment.imageFilename, pointSize: 900)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                if let image = loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Theme.heroGradient
                }
            }
            .frame(width: 900, height: 675)
            .clipped()
            .overlay(alignment: .bottomLeading) {
                HStack(spacing: 8) {
                    Image(systemName: moment.mood.symbol)
                    Text(moment.mood.label)
                }
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(moment.mood.color, in: Capsule())
                .padding(24)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(Self.dateFormatter.string(from: moment.displayDate).uppercased())
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)

                if !moment.title.isEmpty {
                    Text(moment.title)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                }
                if !moment.caption.isEmpty {
                    Text(moment.caption)
                        .font(.system(size: 30, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.9))
                        .lineLimit(4)
                }

                HStack(spacing: 8) {
                    Circle().fill(Theme.accent).frame(width: 22, height: 22)
                    Text("Glimpse")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(28)
            .frame(width: 900, alignment: .leading)
            .background(Theme.surface)
        }
        .frame(width: 900)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}
