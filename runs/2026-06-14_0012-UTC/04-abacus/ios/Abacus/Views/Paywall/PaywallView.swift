import SwiftUI

/// Honest one-time-unlock paywall. Backed by @AppStorage("isPro") for this build.
struct PaywallView: View {
    @AppStorage("isPro") private var isPro = false
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var justUnlocked = false

    private struct Perk: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let detail: String
    }

    private let perks: [Perk] = [
        Perk(symbol: "infinity", title: "Unlimited scenarios",
             detail: "Save every loan and home you're weighing — not just one."),
        Perk(symbol: "rectangle.on.rectangle", title: "Side-by-side compare",
             detail: "Put two loans head to head on payment, interest, and payoff."),
        Perk(symbol: "arrow.triangle.2.circlepath", title: "Refinance analyzer",
             detail: "Find your break-even point and lifetime savings."),
        Perk(symbol: "square.and.arrow.up", title: "CSV export",
             detail: "Export the full amortization schedule to share or archive.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    VStack(spacing: 12) {
                        ForEach(perks) { perk in perkRow(perk) }
                    }
                    if isPro { unlockedBanner } else { purchase }
                    footnote
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .background(Theme.bg)
            .navigationTitle("Abacus Pro")
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
                Circle().fill(Theme.accentSoft).frame(width: 88, height: 88)
                Image(systemName: "seal.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text("Unlock everything, once")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("A single purchase. No subscriptions, no ads — ever.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
    }

    private func perkRow(_ perk: Perk) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Theme.accentSoft)
                    .frame(width: 42, height: 42)
                Image(systemName: perk.symbol)
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(perk.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(perk.detail)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private var purchase: some View {
        VStack(spacing: 10) {
            Button {
                isPro = true
                justUnlocked = true
                Haptics.success(enabled: settings.hapticsEnabled)
            } label: {
                VStack(spacing: 2) {
                    Text("Unlock Abacus Pro")
                        .font(Theme.rounded(17, .semibold))
                    Text("$4.99 · one-time")
                        .font(Theme.rounded(13))
                        .opacity(0.9)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(Color.white)
            }
            Button("Restore purchase") {
                // Local restore for this build: re-applies the stored flag.
                if isPro {
                    Haptics.success(enabled: settings.hapticsEnabled)
                } else {
                    Haptics.warning(enabled: settings.hapticsEnabled)
                }
            }
            .font(Theme.rounded(14, .medium))
            .foregroundStyle(Theme.accent)
        }
    }

    private var unlockedBanner: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Theme.good)
                    .accessibilityHidden(true)
                Text(justUnlocked ? "You're all set — thank you!" : "Abacus Pro is active")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
            }
            Button("Done") { dismiss() }
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(16)
        .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var footnote: some View {
        Text("Demo build: unlocks locally on this device. A production release wires StoreKit 2 for a real one-time purchase and restore.")
            .font(Theme.rounded(11))
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}
