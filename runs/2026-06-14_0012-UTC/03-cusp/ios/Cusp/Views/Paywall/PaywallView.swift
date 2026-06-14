import SwiftUI

/// Honest one-time unlock screen. Backed by `@AppStorage("isPro")` for this build;
/// production wires StoreKit 2. The free tier is genuinely useful, so this never
/// blocks the core ability to make countdowns.
struct PaywallView: View {
    let reason: PaywallReason
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @State private var unlocking = false
    @State private var showRestoreNote = false

    private let benefits: [(String, String)] = [
        ("infinity", "Unlimited events"),
        ("paintpalette.fill", "All eight gradient themes"),
        ("square.and.arrow.up", "Share beautiful countdown cards"),
        ("calendar", "Month calendar view"),
        ("heart.fill", "Support an indie, ad-free app")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    benefitsList
                    unlockButton
                    restoreButton
                    footnote
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Cusp Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close")
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(Theme.accentSoft).frame(width: 96, height: 96)
                Image(systemName: "hourglass")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text(reason.headline)
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(reason.detail)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    private var benefitsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(benefits.enumerated()), id: \.offset) { i, b in
                HStack(spacing: 14) {
                    Image(systemName: b.0)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 26)
                        .accessibilityHidden(true)
                    Text(b.1)
                        .font(Theme.rounded(16))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.good)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 13)
                .padding(.horizontal, 16)
                if i < benefits.count - 1 {
                    Divider().overlay(Theme.hairline).padding(.leading, 56)
                }
            }
        }
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    private var unlockButton: some View {
        Button {
            unlock()
        } label: {
            HStack {
                if unlocking {
                    ProgressView().tint(.white)
                } else {
                    Text(isPro ? "Pro unlocked" : "Unlock \(Pro.productName) · \(Pro.priceLabel)")
                        .font(Theme.rounded(17, .semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isPro ? AnyShapeStyle(Theme.good) : AnyShapeStyle(Theme.accent),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(isPro || unlocking)
    }

    private var restoreButton: some View {
        Button {
            showRestoreNote = true
            // In this build there is no server; a real restore happens in production.
        } label: {
            Text("Restore Purchase")
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.accent)
        }
        .alert("Restore", isPresented: $showRestoreNote) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(isPro
                 ? "Cusp Pro is already active on this device."
                 : "No purchase found on this device. In the App Store build, your previous purchase restores here.")
        }
    }

    private var footnote: some View {
        Text("One-time purchase, no subscription. Demo build: unlocks locally on this device; the production build wires StoreKit 2.")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }

    private func unlock() {
        guard !isPro else { return }
        unlocking = true
        Haptics.tap(enabled: settings.hapticsEnabled)
        // Simulate the brief purchase round-trip, then unlock locally.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isPro = true
            unlocking = false
            Haptics.success(enabled: settings.hapticsEnabled)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { dismiss() }
        }
    }
}
