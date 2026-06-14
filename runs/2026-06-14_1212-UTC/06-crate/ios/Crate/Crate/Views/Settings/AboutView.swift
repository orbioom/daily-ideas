import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        ZStack {
                            VinylDisc(labelHue: 0.08, labelFraction: 0.5)
                                .frame(width: 56, height: 56)
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                                .accessibilityHidden(true)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Crate")
                                .font(Theme.serif(28, .bold)).foregroundStyle(Theme.ink)
                            Text("Your record collection & spin log")
                                .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                        }
                    }

                    Text("Crate is a private, beautiful catalogue for vinyl collectors. Log every record with tracklists, Goldmine condition grades and value, track every spin, and watch your collection's stats take shape — the native collection app the marketplace apps never made.")
                        .font(Theme.rounded(15)).foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Everything stays on your device. No account, no feed, no cloud.")
                        .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider().background(Theme.hairline)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Made by Orbioom")
                            .font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.ink)
                        Text("Built with SwiftUI, SwiftData, and Swift Charts for iOS 17.")
                            .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
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
