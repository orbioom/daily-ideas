import SwiftUI

/// About Yield: what it is, the privacy stance, and a clear not-advice disclaimer.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    card(title: "What Yield does",
                         body: "Enter your dividend-paying holdings — shares and dividend-per-share — and Yield projects your annual and monthly income, yield-on-cost, a forward 12-month payout calendar, income by sector, and a DRIP reinvestment projection. No live prices required.")
                    card(title: "Private by design",
                         body: "Yield is offline and manual. There's no account, no brokerage login, and no tracking. Your portfolio is stored only on this device using SwiftData.")
                    card(title: "Not financial advice",
                         body: "Yield is a tracking and education tool. Its projections are simplified models based on the numbers you enter — they are not forecasts, recommendations, or financial, investment, or tax advice. Sample holdings shown on first launch are illustrative only and do not reflect live market data.")
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 46))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Yield")
                .font(Theme.rounded(28, .bold)).foregroundStyle(Theme.ink)
            Text("Dividend income, projected.")
                .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    private func card(title: String, body: String) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                Text(body).font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
