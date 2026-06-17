import SwiftUI

/// The Abode Pro paywall. One-time purchase, simulated (no real StoreKit calls).
struct PaywallView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro

    var body: some View {
        NavigationStack {
            ZStack {
                AbodeTheme.appBackground(scheme).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 22) {
                        header
                        featureList
                        purchaseButtons
                        Text("A one-time purchase. The core calculator and full amortization schedule are always free. This demo unlocks instantly without a real transaction.")
                            .font(.caption2)
                            .foregroundStyle(AbodeTheme.secondaryText(scheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Abode Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "house.and.flag.fill")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(AbodeTheme.accent)
                .accessibilityHidden(true)
            Text("Plan every move with confidence")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(AbodeTheme.primaryText(scheme))
            Text("Unlock affordability, refinance, unlimited scenarios, and the extra-payment optimizer.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(AbodeTheme.secondaryText(scheme))
        }
        .accessibilityElement(children: .combine)
    }

    private var featureList: some View {
        VStack(spacing: 12) {
            ForEach(ProStore.features, id: \.title) { feature in
                AbodeCard {
                    HStack(spacing: 14) {
                        Image(systemName: feature.icon)
                            .font(.title3)
                            .foregroundStyle(AbodeTheme.accent)
                            .frame(width: 30)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AbodeTheme.primaryText(scheme))
                            Text(feature.detail)
                                .font(.caption)
                                .foregroundStyle(AbodeTheme.secondaryText(scheme))
                        }
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var purchaseButtons: some View {
        VStack(spacing: 12) {
            if pro.isPro {
                Label("You have Abode Pro", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(AbodeTheme.accent)
            } else {
                Button {
                    pro.unlock()
                    Haptics.success(settings.hapticsEnabled)
                    dismiss()
                } label: {
                    Text("Unlock for \(ProStore.priceDisplay)")
                }
                .buttonStyle(AbodePrimaryButtonStyle())

                Button("Restore purchase") {
                    pro.restore()
                    Haptics.success(settings.hapticsEnabled)
                    dismiss()
                }
                .buttonStyle(AbodeSecondaryButtonStyle())
            }
        }
    }
}
