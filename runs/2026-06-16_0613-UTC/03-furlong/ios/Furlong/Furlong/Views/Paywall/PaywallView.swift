import SwiftUI

struct PaywallView: View {
    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var toast: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    VStack(spacing: 12) {
                        ForEach(Pro.features) { feature in
                            featureRow(feature)
                        }
                    }
                    .padding(.horizontal, 20)

                    priceBlock
                        .padding(.horizontal, 20)

                    Text("Simulated purchase for this build — StoreKit-ready. No account, no subscription, no data leaves your device.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                        .padding(.bottom, 24)
                }
                .padding(.top, 12)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Furlong Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .toast($toast)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Theme.heroGradient)
                    .frame(width: 96, height: 96)
                Image(systemName: "signpost.right.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
            Text("Unlock the full ledger")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
            Text("Export, unlimited trips, multi-vehicle and more — for one fair price.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private func featureRow(_ feature: Pro.Feature) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: feature.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(feature.detail)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var priceBlock: some View {
        VStack(spacing: 12) {
            if isPro {
                Label("Furlong Pro is unlocked", systemImage: "checkmark.seal.fill")
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.vertical, 8)
            } else {
                HStack(spacing: 6) {
                    Text(Pro.price)
                        .font(Theme.mono(30, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("one-time")
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
                PrimaryButton(title: "Unlock Furlong Pro", symbol: "lock.open.fill") {
                    isPro = true
                    Haptics.success(settings.hapticsEnabled)
                    toast = "Pro unlocked — thank you!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
                }
                Button("Restore purchase") {
                    // Simulated restore: re-applies the local entitlement flag.
                    if isPro {
                        toast = "Already unlocked"
                    } else {
                        toast = "No previous purchase found"
                    }
                    Haptics.selection(settings.hapticsEnabled)
                }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.accent)
                Button("Maybe later") { dismiss() }
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }
}
