import SwiftUI

/// One-time purchase paywall for Hush Pro. Simulated — "Unlock" / "Restore"
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
                                        .fill(HushTheme.teal.opacity(0.14))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: f.icon)
                                        .font(.title3)
                                        .foregroundStyle(HushTheme.teal)
                                }
                                .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(f.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(HushTheme.primaryText(scheme))
                                    Text(f.detail)
                                        .font(.caption)
                                        .foregroundStyle(HushTheme.secondaryText(scheme))
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
                            .fill(HushTheme.cardSurface(scheme))
                    )

                    if pro.isPro {
                        Label("Hush Pro unlocked — sleep well!", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(HushTheme.positive)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 10) {
                            Button("Unlock Hush Pro · \(ProStore.priceDisplay)") {
                                pro.unlock()
                                Haptics.success(settings.hapticsEnabled)
                            }
                            .buttonStyle(HushPrimaryButtonStyle())

                            Button("Restore purchase") {
                                pro.restore()
                                Haptics.success(settings.hapticsEnabled)
                            }
                            .buttonStyle(HushSecondaryButtonStyle())
                        }
                    }

                    Text("One-time purchase, no subscription. The core noises, three preset mixes, three layers and the basic timer stay free forever.")
                        .font(.caption2)
                        .foregroundStyle(HushTheme.secondaryText(scheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(20)
            }
            .hushScreenBackground(scheme)
            .navigationTitle("Hush Pro")
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
                Circle().fill(HushTheme.teal.opacity(0.16)).frame(width: 88, height: 88)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(HushTheme.teal)
            }
            .accessibilityHidden(true)
            Text("Unlock the full library")
                .font(.title2.weight(.bold))
                .foregroundStyle(HushTheme.primaryText(scheme))
            Text("Every synthesized sound, unlimited layers and saved mixes, and long, gentle sleep timers — for one small price.")
                .font(.subheadline)
                .foregroundStyle(HushTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
        }
    }
}
