import SwiftUI

/// A calm gate shown where a Pro feature lives, with an unlock CTA.
struct ProLockedView: View {
    let symbol: String
    let title: String
    let message: String
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: symbol)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.serif(.title2))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.callout)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                showPaywall = true
            } label: {
                Label("Unlock Numen Pro", systemImage: "lock.open.fill")
                    .font(Theme.rounded(15, .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
        }
        .padding(28)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }
}
