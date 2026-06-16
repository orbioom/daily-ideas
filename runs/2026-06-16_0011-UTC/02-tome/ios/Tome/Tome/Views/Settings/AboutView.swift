import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Theme.heroGradient)
                            .frame(width: 96, height: 96)
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(.white)
                            .accessibilityHidden(true)
                    }
                    .padding(.top, 12)

                    Text("Tome")
                        .font(Theme.serif(30, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("A calm, private reading tracker. Shelve your books, log your sessions, keep a reading challenge, and watch your year take shape — all on your device.")
                        .font(Theme.rounded(16))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 12) {
                        aboutRow("lock.shield", "Private by design",
                                 "Everything lives in on-device storage. No account, no tracking, nothing uploaded.")
                        aboutRow("chart.pie", "Free stats",
                                 "Your reading year, charted — the analytics other apps charge a subscription for.")
                        aboutRow("heart", "Made for readers",
                                 "Warm, paper-inspired design with generated covers, built by the Orbioom studio.")
                    }
                    .padding(18)
                    .cardSurface()
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }

    private func aboutRow(_ symbol: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(body)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
