import SwiftUI

/// Simulated one-time Pro unlock. StoreKit-ready scaffolding — no real
/// purchase is made; `ProStore.unlock()` flips the @AppStorage flag.
struct PaywallView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var unlocked = false

    private let perks: [(icon: String, title: String, detail: String)] = [
        ("infinity", "Unlimited markers & panels", "Track every marker and your full history — no free-tier caps."),
        ("square.and.arrow.up", "Doctor-ready export", "Share clean CSV and plain-text summaries with your clinician."),
        ("plus.square.on.square", "Custom markers", "Add labs Assay's catalog doesn't cover, with your own ranges."),
        ("chart.line.uptrend.xyaxis", "Trend insights", "In-range-over-time and most-out-of-range analytics."),
        ("target", "Optimal-range scoring", "See every result against tighter optimal targets, not just standard.")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 22) {
                        header
                        perksList
                        priceBlock
                        legal
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Maybe later") { dismiss() }
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.heroGradient).frame(width: 88, height: 88)
                Image(systemName: "sparkles")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
            Text("Assay Pro")
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
            Text("Own your bloodwork. One payment, yours forever — no subscription.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var perksList: some View {
        VStack(spacing: 12) {
            ForEach(perks, id: \.title) { perk in
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.accentSoft)
                            .frame(width: 40, height: 40)
                        Image(systemName: perk.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(perk.title)
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text(perk.detail)
                            .font(.footnote)
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
    }

    private var priceBlock: some View {
        VStack(spacing: 12) {
            Text(ProStore.priceLabel)
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(Theme.ink)
            if pro.isPro {
                Label("Pro is unlocked", systemImage: "checkmark.seal.fill")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.good)
            } else {
                Button {
                    pro.unlock()
                    Haptics.success(enabled: settings.hapticsEnabled)
                    if reduceMotion {
                        unlocked = true
                    } else {
                        withAnimation(.spring) { unlocked = true }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss() }
                } label: {
                    Text("Unlock Assay Pro")
                        .font(Theme.rounded(17, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Theme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                Button("Restore purchase") {
                    pro.restore()
                    Haptics.success(enabled: settings.hapticsEnabled)
                    dismiss()
                }
                .font(.callout)
                .foregroundStyle(Theme.accent)
            }
            if unlocked {
                Label("Thank you!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Theme.good)
                    .transition(.opacity)
            }
        }
    }

    private var legal: some View {
        Text("Simulated purchase for this demo build (StoreKit-ready). The free version remains fully usable for core tracking.")
            .font(.caption2)
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}
