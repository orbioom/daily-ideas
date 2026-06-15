import SwiftUI

/// Calm, honest paywall. Flips the local `isPro` flag (no StoreKit in this build).
struct PaywallView: View {
    let reason: PaywallReason

    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var restoredMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    benefits
                    purchase
                    contrast
                }
                .padding(24)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Hue Pro")
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
                    .font(.system(size: 42)).foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text(reason.title)
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(reason.subtitle)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Pro.benefits, id: \.self) { benefit in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    Text(benefit)
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .cardSurface()
    }

    private var purchase: some View {
        VStack(spacing: 12) {
            if isPro {
                Label("Hue Pro is active", systemImage: "checkmark.seal.fill")
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.good)
            } else {
                Button {
                    isPro = true
                } label: {
                    VStack(spacing: 2) {
                        Text("Unlock Hue Pro").font(Theme.rounded(18, .semibold))
                        Text("\(Pro.priceLabel) • one-time, no subscription")
                            .font(Theme.rounded(13))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: Theme.corner).fill(Theme.accent))
                    .foregroundStyle(.white)
                }

                Button("Restore purchase") { restore() }
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.accent)
            }
            if let restoredMessage {
                Text(restoredMessage)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private var contrast: some View {
        VStack(spacing: 6) {
            Text("Why one price?")
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.ink)
            Text("Other coloring apps push weekly subscriptions, ads, and watermarks on everything. Hue is a single fair purchase that stays yours — and your art never leaves your device.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }

    private func restore() {
        // No real StoreKit in this build; restoring re-applies the local flag if set.
        if isPro {
            restoredMessage = "Your Hue Pro purchase is active."
        } else {
            restoredMessage = "No previous purchase found on this device."
        }
    }
}
