import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Theme.dawnGradient)
                                .frame(width: 56, height: 56)
                                .accessibilityHidden(true)
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(Theme.onHeader)
                                .accessibilityHidden(true)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daybreak")
                                .font(Theme.rounded(28, .bold))
                                .foregroundStyle(Theme.ink)
                            Text("Routine builder & guided runner")
                                .font(Theme.rounded(14))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }

                    Text("Daybreak turns small habits into routines you can actually finish. Chain a few steps into a morning, evening, or focus routine, then press Start — Daybreak walks you through each step, counting down timed ones and waiting for the rest.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Every run feeds your streak, heatmap, and minutes — so a calm morning becomes a habit you can see. Everything stays on this device. No account, no feed, no cloud.")
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
