import SwiftUI

/// One-time purchase paywall for Fuel Pro. Simulated — "Unlock" / "Restore"
/// flip the persisted entitlement. StoreKit-ready in spirit.
struct PaywallView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(ProStore.self) private var pro
    @Environment(AppSettings.self) private var settings

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header

                    VStack(spacing: 12) {
                        ForEach(Array(ProStore.features.enumerated()), id: \.offset) { _, f in
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(FuelTheme.orange.opacity(0.14))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: f.icon)
                                        .font(.title3)
                                        .foregroundStyle(FuelTheme.orange)
                                }
                                .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(f.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(FuelTheme.primaryText(scheme))
                                    Text(f.detail)
                                        .font(.caption)
                                        .foregroundStyle(FuelTheme.secondaryText(scheme))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(FuelTheme.cardSurface(scheme))
                    )

                    if pro.isPro {
                        Label("Fuel Pro unlocked — thank you!", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(FuelTheme.positive)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 10) {
                            Button("Unlock Fuel Pro · \(ProStore.priceDisplay)") {
                                pro.unlock()
                                Haptics.success(settings.hapticsEnabled)
                            }
                            .buttonStyle(FuelPrimaryButtonStyle())

                            Button("Restore purchase") {
                                pro.restore()
                                Haptics.success(settings.hapticsEnabled)
                            }
                            .buttonStyle(FuelSecondaryButtonStyle())
                        }
                    }

                    Text("One-time purchase, no subscription. The core calculator (targets + macros) stays free forever.")
                        .font(.caption2)
                        .foregroundStyle(FuelTheme.secondaryText(scheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(20)
            }
            .fuelScreenBackground(scheme)
            .navigationTitle("Fuel Pro")
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
            ZStack {
                Circle().fill(FuelTheme.orange.opacity(0.16)).frame(width: 88, height: 88)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(FuelTheme.orange)
            }
            .accessibilityHidden(true)
            Text("Go further with Pro")
                .font(.title2.weight(.bold))
                .foregroundStyle(FuelTheme.primaryText(scheme))
            Text("Unlock adaptive coaching that keeps your targets accurate every week.")
                .font(.subheadline)
                .foregroundStyle(FuelTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
        }
    }
}
