import SwiftUI

/// Simulated one-time Pro paywall. Sets the persisted `isPro` flag; no real StoreKit calls.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro

    private let features: [(String, String)] = [
        ("infinity", "Unlimited savings goals"),
        ("square.split.2x2", "Smart lump-sum allocation"),
        ("chart.xyaxis.line", "Advanced insights & projections"),
        ("square.and.arrow.up", "CSV export of your history"),
        ("lock.shield", "Private — no bank logins, ever")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 22) {
                        header
                        featureList
                        priceBlock
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Nest Pro")
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
                Circle().fill(Theme.accentSoft).frame(width: 96, height: 96)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            Text("Grow without limits")
                .font(Theme.serif(26, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("A one-time purchase. No subscriptions, no fees on your savings.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var featureList: some View {
        VStack(spacing: 14) {
            ForEach(features, id: \.1) { feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.0)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    Text(feature.1)
                        .font(Theme.rounded(16))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var priceBlock: some View {
        if pro.isPro {
            VStack(spacing: 10) {
                Label("You have Nest Pro", systemImage: "checkmark.seal.fill")
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.good)
                Text("Thank you for supporting Nest.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        } else {
            VStack(spacing: 12) {
                Text("\(ProStore.price) once")
                    .font(Theme.money(22, .bold))
                    .foregroundStyle(Theme.ink)
                PrimaryButton(title: "Unlock Nest Pro", systemImage: "sparkles") {
                    pro.unlock()
                    Haptics.success(settings.hapticsEnabled)
                    dismiss()
                }
                Button("Restore purchase") {
                    pro.unlock()
                    Haptics.success(settings.hapticsEnabled)
                    dismiss()
                }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
            }
            .padding(.top, 8)
        }
    }
}
