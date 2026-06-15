import SwiftUI

/// The Quill Pro paywall. One-time unlock, simulated via `@AppStorage("isPro")`.
struct PaywallView: View {
    let reason: PaywallReason

    @AppStorage("isPro") private var isPro: Bool = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var unlocked = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    benefits
                    pricing
                    footer
                }
                .padding(24)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(reason.headline)
                .font(Theme.serif(28, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(reason.message)
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 12)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Pro.benefits, id: \.title) { benefit in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: benefit.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(benefit.title)
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text(benefit.detail)
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(20)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
    }

    private var pricing: some View {
        VStack(spacing: 6) {
            Text(Pro.priceLabel)
                .font(Theme.rounded(34, .bold))
                .foregroundStyle(Theme.ink)
            Text("One-time purchase · No subscription")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Pro.priceLabel), one-time purchase, no subscription")
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.success(settings.hapticsEnabled)
                if reduceMotion {
                    isPro = true
                    dismiss()
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) { unlocked = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isPro = true
                        dismiss()
                    }
                }
            } label: {
                Text(unlocked ? "Unlocked!" : "Unlock Quill Pro")
                    .font(Theme.rounded(17, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Unlock Quill Pro for \(Pro.priceLabel)")

            Button("Restore Purchase") {
                // Simulated restore — in production this calls StoreKit 2's
                // AppStore.sync() / Transaction.currentEntitlements.
                Haptics.tap(settings.hapticsEnabled)
                isPro = true
                dismiss()
            }
            .font(Theme.rounded(15))
            .foregroundStyle(Theme.accent)

            Text("Purchases are simulated locally for this build. Production wires in StoreKit 2.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }
}
