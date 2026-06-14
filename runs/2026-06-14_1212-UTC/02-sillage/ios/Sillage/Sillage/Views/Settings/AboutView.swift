import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(LinearGradient(colors: [Theme.accent, NoteFamily.woody.hueDeep],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 56, height: 56)
                            Image(systemName: "drop.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white)
                        }
                        .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sillage")
                                .font(Theme.serif(28, .bold))
                                .foregroundStyle(Theme.ink)
                            Text("Your private fragrance collection")
                                .font(Theme.rounded(14))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }

                    Text("Sillage is the elegant native home for fragrance lovers. Catalog every bottle with its house, concentration, and full note pyramid; log each wear; and learn your taste — your favorite note families, season and occasion habits, and cost per wear.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Everything stays on your device. No account, no feed, no ads.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Made by Orbioom")
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("Built with SwiftUI, SwiftData, and Swift Charts for iOS 17.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .padding(22)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }
}
