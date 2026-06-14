import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 46))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Skillet")
                                .font(Theme.serif(28, .bold))
                                .foregroundStyle(Theme.ink)
                            Text("Cook with what you have")
                                .font(Theme.rounded(14))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }

                    Text("Tell Skillet what's in your kitchen and it instantly ranks recipes by how much you can already make — \"ready to cook\" first, then the ones you're a single ingredient away from. A smart shopping list shows which item unlocks the most meals.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Everything stays on your device. No account, no feed, no cloud.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Made by Orbioom")
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("Built with SwiftUI and SwiftData for iOS 17.")
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
