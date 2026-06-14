import SwiftUI

/// Honest one-time-unlock paywall. Backed by `@AppStorage("isPro")` for this build.
struct PaywallView: View {
    @AppStorage("isPro") private var isPro = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var unlocking = false

    private let benefits: [(String, String)] = [
        ("infinity", "Unlimited mind maps"),
        ("paintpalette.fill", "Every canvas theme"),
        ("square.and.arrow.up", "Export to Markdown outline"),
        ("heart.fill", "Support a tiny indie studio")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    benefitList

                    if isPro {
                        unlockedBadge
                    } else {
                        unlockButton
                        restoreButton
                    }

                    Text("Demo build: unlocks locally on this device. Production wires StoreKit 2 for a real one-time purchase.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Aster Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.accentSoft).frame(width: 110, height: 110)
                Image(systemName: "sparkles")
                    .font(.system(size: 46))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text("Unlock the full canvas")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("The free tier gives you up to \(ProLimits.freeMapLimit) maps and two themes. Go Pro once \u{2014} keep it forever.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
    }

    private var benefitList: some View {
        CardSection {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(benefits, id: \.1) { item in
                    HStack(spacing: 14) {
                        Image(systemName: item.0)
                            .foregroundStyle(Theme.accent)
                            .frame(width: 26)
                        Text(item.1)
                            .font(Theme.rounded(16, .medium))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.good)
                    }
                }
            }
        }
    }

    private var unlockButton: some View {
        Button {
            unlocking = true
            Haptics.success()
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                isPro = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss() }
        } label: {
            VStack(spacing: 2) {
                Text("Unlock Aster Pro")
                    .font(Theme.rounded(17, .semibold))
                Text("$6.99 \u{00B7} one-time")
                    .font(Theme.rounded(12))
                    .opacity(0.9)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(unlocking)
    }

    private var restoreButton: some View {
        Button("Restore Purchase") {
            Haptics.tap()
            // Demo: nothing to restore unless already unlocked.
        }
        .font(Theme.rounded(15, .medium))
        .foregroundStyle(Theme.accent)
    }

    private var unlockedBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.good)
            Text("Aster Pro is unlocked. Thank you!")
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.ink)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Theme.good.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
