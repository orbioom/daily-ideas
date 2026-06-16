import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var pro: ProStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    benefits
                    purchaseButton
                    footerButtons
                    Text("Simulated purchase. StoreKit-ready: this build unlocks instantly and stores the flag on-device.")
                        .font(Theme.rounded(11))
                        .foregroundStyle(Theme.inkFaint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle("Deed Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .toast($restoreMessage)
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.heroGradient)
                    .frame(width: 92, height: 92)
                Image(systemName: "key.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            Text("Unlock your whole portfolio")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("One payment. Yours forever. No subscription.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
    }

    private var benefits: some View {
        VStack(spacing: 12) {
            ForEach(ProBenefit.all) { benefit in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: benefit.systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 30)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(benefit.title)
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text(benefit.detail)
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(18)
        .cardSurface(padding: 4)
    }

    private var purchaseButton: some View {
        Button {
            Haptics.notify(.success, enabled: settings.hapticsEnabled)
            pro.unlock()
            dismiss()
        } label: {
            VStack(spacing: 2) {
                Text("Unlock \(ProStore.productName)")
                    .font(Theme.rounded(17, .bold))
                Text("\(ProStore.priceLabel) · one-time")
                    .font(Theme.rounded(13, .medium))
                    .opacity(0.9)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous))
            .foregroundStyle(.white)
        }
        .accessibilityLabel("Unlock Deed Pro for \(ProStore.priceLabel), one-time payment")
    }

    private var footerButtons: some View {
        VStack(spacing: 10) {
            Button("Restore Purchase") {
                if pro.restore() {
                    restoreMessage = "Pro restored"
                } else {
                    restoreMessage = "No purchase found to restore"
                }
                Haptics.selection(enabled: settings.hapticsEnabled)
            }
            .font(Theme.rounded(15, .medium))
            .foregroundStyle(Theme.accent)

            Button("Maybe later") { dismiss() }
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
        }
    }
}
