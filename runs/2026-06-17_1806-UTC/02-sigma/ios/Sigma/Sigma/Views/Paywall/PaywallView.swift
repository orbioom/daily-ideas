import SwiftUI

/// Simulated one-time Pro unlock (StoreKit-ready). Lists five real unlocks.
struct PaywallView: View {
    @EnvironmentObject private var pro: ProStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showUnlocked = false

    private let perks: [(icon: String, title: String, body: String)] = [
        ("infinity", "Unlimited history", "Keep every calculation forever — no 50-entry cap."),
        ("atom", "Constants library", "Insert 16 physics & math constants like c, g and Avogadro's number."),
        ("paintpalette", "Extra themes", "Graphite, Paper and Solar key palettes."),
        ("scope", "High precision mode", "More decimal places for demanding work."),
        ("heart", "Support an indie tool", "One payment, no ads, no subscriptions ever.")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 22) {
                        header
                        VStack(spacing: 14) {
                            ForEach(perks, id: \.title) { perk in
                                perkRow(perk)
                            }
                        }
                        .padding(18)
                        .background(RoundedRectangle(cornerRadius: Theme.cornerCard, style: .continuous).fill(Theme.surface))

                        unlockButton
                        Button("Restore Purchase") {
                            pro.restore()
                            finishUnlock()
                        }
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)

                        Button("Maybe later") { dismiss() }
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.inkSoft)
                            .padding(.bottom, 8)

                        Text("Simulated purchase for this build. StoreKit-ready: a single non-consumable would set the same entitlement.")
                            .font(Theme.rounded(11))
                            .foregroundStyle(Theme.inkFaint)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Sigma Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.inkSoft)
                            .accessibilityLabel("Close")
                    }
                }
            }
            .toast(isPresented: $showUnlocked, message: "Pro unlocked", systemImage: "sparkles")
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Theme.accent)
                    .frame(width: 84, height: 84)
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(Theme.accentInk)
                    .accessibilityHidden(true)
            }
            Text("Unlock everything, once.")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("The whole calculator is free. Pro adds these extras for a single payment.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.top, 12)
    }

    private func perkRow(_ perk: (icon: String, title: String, body: String)) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: perk.icon)
                .font(.system(size: 20))
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(perk.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(perk.body)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var unlockButton: some View {
        Button {
            pro.unlock()
            finishUnlock()
        } label: {
            VStack(spacing: 2) {
                Text("Unlock Sigma Pro")
                    .font(Theme.rounded(18, .bold))
                Text(ProStore.price + " · one-time")
                    .font(Theme.rounded(13, .medium))
                    .opacity(0.85)
            }
            .foregroundStyle(Theme.accentInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.accent))
        }
        .accessibilityLabel("Unlock Sigma Pro for \(ProStore.price), one-time payment")
    }

    private func finishUnlock() {
        Haptics.success(enabled: settings.hapticsEnabled)
        showUnlocked = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
    }
}
