import SwiftUI

/// Honest one-time Pro unlock. Backed by @AppStorage("isPro"). Clearly labeled as
/// a local unlock for this build; production would wire StoreKit 2.
struct PaywallView: View {
    @AppStorage("isPro") private var isPro = false
    @Environment(\.dismiss) private var dismiss
    @State private var justUnlocked = false

    private let features: [(String, String, String)] = [
        ("checkmark.shield.fill", "No-guess mode", "Every board solvable by pure logic — never lose to a coin flip again."),
        ("slider.horizontal.3", "Custom boards", "Pick your own size and mine density, from gentle to brutal."),
        ("paintbrush.fill", "Themes", "Light, dark and system — your field, your look."),
        ("square.and.arrow.up", "CSV export", "Take your full game history with you anytime.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    VStack(spacing: 12) {
                        ForEach(Array(features.enumerated()), id: \.offset) { pair in
                            featureRow(pair.element)
                        }
                    }
                    priceBlock
                    footnote
                }
                .padding(22)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Sapper Pro")
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
                Image(systemName: "sparkles")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text("Unlock the full field")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
            Text("Sapper is free forever with no ads. Pro adds the extras for players who want more control.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func featureRow(_ feature: (String, String, String)) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: feature.0)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(feature.1)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(feature.2)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.hairline))
    }

    private var priceBlock: some View {
        VStack(spacing: 12) {
            if isPro {
                Label("Pro is unlocked. Thank you!", systemImage: "checkmark.seal.fill")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.good)
            } else {
                Text("Sapper Pro · $2.99 one-time")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                PrimaryButton(title: "Unlock Sapper Pro", systemImage: "lock.open.fill") {
                    withAnimation { isPro = true; justUnlocked = true }
                }
                Button("Restore purchase") {
                    // In this build there is nothing remote to restore; reflect state honestly.
                    withAnimation { isPro = true }
                }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.accent)
            }
            if justUnlocked {
                Text("Pro features are now available across the app.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.good)
            }
        }
    }

    private var footnote: some View {
        Text("Demo build: unlocks locally on this device; production wires StoreKit 2. No ads, no subscription — a single one-time purchase.")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }
}

#Preview {
    PaywallView()
}
