import SwiftUI

/// Identifiable wrapper so a UIImage can drive a `.sheet(item:)`.
struct ShareableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// A share sheet presenting the rendered wallpaper image. No permissions required.
struct ShareSheetView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 360)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 18, y: 8)
                    .accessibilityLabel("Rendered wallpaper")
                    .padding(.horizontal, 40)

                ShareLink(
                    item: Image(uiImage: image),
                    preview: SharePreview("Mural wallpaper", image: Image(uiImage: image))
                ) {
                    Label("Share image", systemImage: "square.and.arrow.up")
                        .font(Theme.rounded(16, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                Spacer()
            }
            .padding(.top, 24)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
