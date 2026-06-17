import SwiftUI

/// One-time purchase paywall for Lace Pro. Simulated — "Unlock" / "Restore"
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
                                        .fill(Theme.coral.opacity(0.14))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: f.icon)
                                        .font(.title3)
                                        .foregroundStyle(Theme.coral)
                                }
                                .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(f.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.primaryText(scheme))
                                    Text(f.detail)
                                        .font(.caption)
                                        .foregroundStyle(Theme.secondaryText(scheme))
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
                            .fill(Theme.cardSurface(scheme))
                    )

                    if pro.isPro {
                        Label("Lace Pro unlocked — thank you!", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.positive)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 10) {
                            Button("Unlock Lace Pro · \(ProStore.priceDisplay)") {
                                pro.unlock()
                                Haptics.success(settings.hapticCues)
                            }
                            .buttonStyle(LacePrimaryButtonStyle())

                            Button("Restore purchase") {
                                pro.restore()
                                Haptics.success(settings.hapticCues)
                            }
                            .buttonStyle(LaceSecondaryButtonStyle())
                        }
                    }

                    Text("One-time purchase, no subscription. The full Couch to 5K plan, guided player and history stay free forever.")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryText(scheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(20)
            }
            .laceScreenBackground(scheme)
            .navigationTitle("Lace Pro")
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
                Circle().fill(Theme.coral.opacity(0.16)).frame(width: 88, height: 88)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Theme.coral)
            }
            .accessibilityHidden(true)
            Text("Go further with Pro")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.primaryText(scheme))
            Text("Unlock gentler and longer plans, build your own, and export your data.")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText(scheme))
                .multilineTextAlignment(.center)
        }
    }
}
