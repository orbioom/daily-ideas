import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var pro: ProStore
    @Environment(\.dismiss) private var dismiss
    @State private var unlocked = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 22) {
                        header
                        VStack(spacing: 12) {
                            ForEach(pro.perks) { perk in
                                perkRow(perk)
                            }
                        }
                        actions
                        Text("Simulated purchase for this build (StoreKit-ready). One-time unlock — no subscription, no ads, ever.")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Glint Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .overlay {
                if unlocked {
                    successOverlay
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.accent.opacity(0.15)).frame(width: 92, height: 92)
                Image(systemName: "crown.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Theme.gold)
                    .accessibilityHidden(true)
            }
            Text("Unlock everything, once")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("A single, fair purchase. No timers, no lives, no ads — that's a promise.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
    }

    private func perkRow(_ perk: ProStore.Perk) -> some View {
        HStack(spacing: 14) {
            Image(systemName: perk.symbol)
                .font(.system(size: 20))
                .foregroundStyle(Theme.accent)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(perk.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(perk.detail)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: Theme.rMed).fill(Theme.surface))
        .accessibilityElement(children: .combine)
    }

    private var actions: some View {
        VStack(spacing: 10) {
            PrimaryButton(title: "Unlock Glint Pro · \(pro.priceText)", systemImage: "crown.fill") {
                pro.unlock()
                if pro.isPro {
                    Haptics.success()
                    withAnimation { unlocked = true }
                    Task {
                        try? await Task.sleep(nanoseconds: 1_400_000_000)
                        dismiss()
                    }
                }
            }
            Button("Restore Purchases") {
                // Re-reads stored entitlement; if already Pro, dismisses.
                if pro.isPro { dismiss() }
            }
            .font(Theme.rounded(15, .medium))
            .foregroundStyle(Theme.accent)
            Button("Maybe later") { dismiss() }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.good)
                Text("You're Pro!")
                    .font(Theme.rounded(24, .bold))
                    .foregroundStyle(.white)
                Text("All packs, replays, skins, and full stats unlocked.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .padding(30)
        }
        .transition(.opacity)
    }
}
