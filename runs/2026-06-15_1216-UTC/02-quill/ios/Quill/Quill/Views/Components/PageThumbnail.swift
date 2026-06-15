import SwiftUI
import UIKit

/// Displays a page's cached thumbnail, or a paper-template placeholder while
/// one is being generated.
struct PageThumbnail: View {
    let thumbnailData: Data?
    let template: PaperTemplate
    let pageNumber: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                .fill(Theme.paperColor)

            if let data = thumbnailData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Placeholder: render the bare template.
                PaperBackground(template: template)
            }
        }
        .aspectRatio(1 / ThumbnailRenderer.pageAspect, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .overlay(alignment: .bottomTrailing) {
            Text("\(pageNumber)")
                .font(Theme.rounded(11, .semibold))
                .foregroundStyle(Theme.inkSoft)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Theme.surface.opacity(0.9), in: Capsule())
                .padding(6)
                .accessibilityHidden(true)
        }
        .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(pageNumber)")
        .accessibilityAddTraits(.isButton)
    }
}
