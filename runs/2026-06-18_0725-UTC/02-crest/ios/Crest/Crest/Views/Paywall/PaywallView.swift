import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var pro: ProStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var unlocked = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    hero
                    perksList
                    priceCard
                    legalNote
                }
                .padding(24)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Crest Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .overlay { if unlocked { successOverlay } }
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.gold.opacity(0.16)).frame(width: 96, height: 96)
                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.gold)
                    .accessibilityHidden(true)
            }
            Text("Unlock the full table")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("One payment. No ads, no subscriptions, ever.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
    }

    private var perksList: some View {
        VStack(spacing: 12) {
            ForEach(pro.perks) { perk in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.accent.opacity(0.14))
                            .frame(width: 42, height: 42)
                        Image(systemName: perk.icon)
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(perk.title)
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text(perk.detail)
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var priceCard: some View {
        VStack(spacing: 14) {
            if pro.isPro {
                Label("You already have Crest Pro", systemImage: "checkmark.seal.fill")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.accent)
            } else {
                HStack(spacing: 6) {
                    Text(pro.priceLabel)
                        .font(Theme.rounded(28, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("one-time")
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
                PrimaryButton(title: "Unlock Crest Pro", icon: "lock.open.fill") {
                    pro.unlock()
                    Haptics.notify(.success, enabled: settings.hapticsEnabled)
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
                        unlocked = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { dismiss() }
                }
                Button("Restore purchase") {
                    pro.restore()
                    dismiss()
                }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.accent)
                Button("Maybe later") { dismiss() }
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: Theme.radiusTile, style: .continuous).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusTile, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
    }

    private var legalNote: some View {
        Text("Purchase is simulated for this build (StoreKit-ready). The free game — full Three Peaks, a daily deal, random games and stats — stays unlocked for everyone.")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.accent)
                Text("Pro unlocked!")
                    .font(Theme.rounded(22, .bold))
                    .foregroundStyle(Theme.ink)
            }
            .padding(34)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Theme.surface))
        }
        .transition(.opacity)
    }
}
