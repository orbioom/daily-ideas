import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Theme.heroGradient)
                            .frame(width: 96, height: 96)
                        Image(systemName: "house.fill")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .accessibilityHidden(true)

                    VStack(spacing: 6) {
                        Text("Deed")
                            .font(Theme.rounded(28, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("Private rental property & landlord tracker")
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        aboutPoint("lock.shield.fill", "On-device & private", "Your portfolio never leaves your phone. No account, no cloud, no tracking.")
                        aboutPoint("function", "Real investor math", "Cap rate, cash-on-cash, NOI, equity, and GRM — computed the way investors actually use them.")
                        aboutPoint("creditcard.fill", "One-time, not a subscription", "Deed Pro is a single purchase. No recurring fees, ever.")
                    }
                    .padding(18)
                    .cardSurface(padding: 4)

                    Text("Deed is an organizing tool, not financial or tax advice. Verify figures before filing or making investment decisions.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func aboutPoint(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
