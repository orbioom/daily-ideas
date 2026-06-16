import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var pro: ProStore
    @EnvironmentObject private var settings: AppSettings
    @State private var unlocking = false
    @State private var toast: String?

    private let perks: [(symbol: String, title: String, detail: String)] = [
        ("checklist", "All 8 topics", "Practice every category, not just the first two."),
        ("infinity", "Unlimited mock exams", "Take as many full and quick mocks as you like."),
        ("text.book.closed.fill", "Explanations everywhere", "See why each answer is right, including exam review."),
        ("signpost.right.fill", "Full Signs library", "Study all common road signs, drawn and explained."),
        ("chart.line.uptrend.xyaxis", "Progress analytics", "Readiness trends, per-topic accuracy and review lists.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    VStack(spacing: 12) {
                        ForEach(Array(perks.enumerated()), id: \.offset) { _, perk in
                            perkRow(perk)
                        }
                    }
                    purchaseArea
                    legal
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Permit Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Maybe later") { dismiss() }
                        .font(Theme.rounded(15, .medium))
                }
            }
            .toast($toast)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.accent.opacity(0.15)).frame(width: 96, height: 96)
                Image(systemName: "crown.fill").font(.system(size: 44)).foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text(pro.isPro ? "You have Permit Pro" : "Unlock everything")
                .font(Theme.rounded(26, .bold)).foregroundStyle(Theme.ink)
            Text("A clean, ad-free way to pass your permit test — one simple purchase, yours forever.")
                .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
    }

    private func perkRow(_ perk: (symbol: String, title: String, detail: String)) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: perk.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(perk.title).font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                Text(perk.detail).font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var purchaseArea: some View {
        if pro.isPro {
            Label("Pro is active. Thank you!", systemImage: "checkmark.seal.fill")
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.good)
                .padding(.vertical, 8)
        } else {
            VStack(spacing: 10) {
                PrimaryButton(title: "Unlock Permit Pro — \(pro.priceLabel)", systemImage: "lock.open.fill") {
                    purchase()
                }
                Text("One-time purchase. No subscription.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                Button("Restore Purchase") { restore() }
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    private var legal: some View {
        Text("Purchases are simulated in this build (StoreKit-ready). Permit teaches general US rules of the road; always confirm specifics in your state driver handbook.")
            .font(Theme.rounded(11))
            .foregroundStyle(Theme.inkSoft)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }

    private func purchase() {
        Haptics.success(settings.hapticsEnabled)
        pro.unlock()
        toast = "Permit Pro unlocked"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { dismiss() }
    }

    private func restore() {
        pro.restore()
        Haptics.success(settings.hapticsEnabled)
        toast = "Purchase restored"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { dismiss() }
    }
}
