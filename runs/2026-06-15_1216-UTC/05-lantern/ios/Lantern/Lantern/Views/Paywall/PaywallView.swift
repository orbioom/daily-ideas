import SwiftUI

/// Calm, single-purchase paywall. Flips `@AppStorage("isPro")`. No real StoreKit,
/// no network, no account. (Production wires StoreKit 2 in place of `unlock()`.)
struct PaywallView: View {
    let reason: PaywallReason
    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showRestoredNote = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    perksCard
                    purchaseButtons
                    fairnessNote
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Lantern Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.accentSoft).frame(width: 84, height: 84)
                Image(systemName: "lightbulb.max.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(Theme.gold)
            }
            Text(reason.title)
                .font(Theme.serif(24, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(reason.message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    private var perksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Pro.perks, id: \.self) { perk in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.good)
                        .font(.system(size: 18))
                    Text(perk)
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 0)
                }
            }
        }
        .cardSurface()
    }

    private var purchaseButtons: some View {
        VStack(spacing: 12) {
            if isPro {
                Label("Lantern Pro is unlocked", systemImage: "checkmark.seal.fill")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.good)
                    .padding(.vertical, 12)
            } else {
                Button {
                    unlock()
                } label: {
                    VStack(spacing: 2) {
                        Text("Unlock Lantern Pro")
                            .font(Theme.rounded(17, .semibold))
                        Text("\(Pro.priceLabel) · one-time · no subscription")
                            .font(Theme.rounded(12))
                            .opacity(0.9)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
                }

                Button("Restore Purchase") { restore() }
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.accent)
            }

            if showRestoredNote {
                Text("No previous purchase found on this device.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
    }

    private var fairnessNote: some View {
        Text("Lantern has no ads, no pop-ups, and never sells your data. One small, optional unlock keeps the lights on.")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }

    private func unlock() {
        Haptics.win(enabled: settings.hapticsEnabled)
        withAnimation { isPro = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss() }
    }

    private func restore() {
        // Simulated: in production, StoreKit 2 `AppStore.sync()` / current
        // entitlements would set this. Here, no purchase exists to restore.
        showRestoredNote = true
    }
}
