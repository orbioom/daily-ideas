import SwiftUI

/// One-time Seek Pro unlock. Simulated purchase (StoreKit-ready).
struct PaywallView: View {
    @EnvironmentObject private var pro: ProStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showThanks = false

    private let perks: [Perk] = [
        Perk(icon: "square.grid.3x3.fill", title: "All 12 themed packs", detail: "Every pack from Animals to Kitchen, unlocked."),
        Perk(icon: "infinity", title: "Unlimited puzzles", detail: "Play every puzzle in every pack and difficulty."),
        Perk(icon: "calendar.badge.clock", title: "Daily archive replay", detail: "Revisit and replay past daily puzzles."),
        Perk(icon: "paintpalette.fill", title: "Extra highlight themes", detail: "Five band colors to match your style."),
        Perk(icon: "lightbulb.fill", title: "Unlimited hints", detail: "Never get stuck — reveal a letter anytime.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    VStack(spacing: 12) {
                        ForEach(perks) { perk in
                            perkRow(perk)
                        }
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 10) {
                        PrimaryButton(title: "Unlock Seek Pro — \(pro.priceLabel)", systemImage: "crown.fill") {
                            pro.unlock()
                            Haptics.notify(.success, enabled: settings.hapticsEnabled)
                            showThanks = true
                        }
                        Button("Restore Purchase") {
                            pro.restore()
                            showThanks = true
                        }
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.accent)

                        Button("Maybe later") { dismiss() }
                            .font(Theme.rounded(15, .medium))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .padding(.horizontal, 20)

                    Text("One-time purchase. No subscription, no ads, ever. Restores across your devices.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 24)
                }
                .padding(.top, 12)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Seek Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close")
                }
            }
            .alert("Welcome to Seek Pro!", isPresented: $showThanks) {
                Button("Let's go") { dismiss() }
            } message: {
                Text("Everything is unlocked. Enjoy a calm, ad-free word search.")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.accent.opacity(0.15)).frame(width: 96, height: 96)
                Image(systemName: "crown.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text("Unlock the full Seek")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
            Text("Pay once. Keep it forever.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.top, 8)
    }

    private func perkRow(_ perk: Perk) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.accent.opacity(0.14))
                    .frame(width: 42, height: 42)
                Image(systemName: perk.icon)
                    .font(.system(size: 18, weight: .semibold))
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
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

private struct Perk: Identifiable {
    let icon: String
    let title: String
    let detail: String
    var id: String { title }
}
