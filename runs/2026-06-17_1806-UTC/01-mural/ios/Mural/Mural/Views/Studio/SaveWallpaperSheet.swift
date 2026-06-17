import SwiftUI

/// A compact sheet to name a wallpaper before saving it to the library.
struct SaveWallpaperSheet: View {
    @Binding var name: String
    var onComplete: (Bool) -> Void
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Name this wallpaper")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                TextField("Wallpaper name", text: $name)
                    .font(Theme.rounded(18, .medium))
                    .focused($focused)
                    .padding(14)
                    .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous))
                    .submitLabel(.done)
                    .onSubmit { onComplete(true) }
                PrimaryButton(title: "Save to Library", systemImage: "square.and.arrow.down.fill") {
                    onComplete(true)
                }
                Spacer(minLength: 0)
            }
            .padding(20)
            .background(Theme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onComplete(false) }
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .onAppear { focused = true }
        }
    }
}
