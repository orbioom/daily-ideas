import SwiftUI

/// Simulated, StoreKit-ready paywall. Sets `isPro` and dismisses on purchase.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("isPro") private var isPro = false
    @State private var unlocked = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    hero
                    featureList
                    priceCard
                    buttons
                    footnote
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
            }

            if unlocked {
                VStack {
                    Spacer()
                    SuccessToast(text: "Welcome to Fetch Pro!")
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.inkSoft.opacity(0.6))
            }
            .padding(16)
            .accessibilityLabel("Close")
        }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(Theme.accent.opacity(0.15)).frame(width: 110, height: 110)
                Image(systemName: "pawprint.circle.fill")
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            .padding(.top, 30)
            Text("Fetch Pro")
                .font(Theme.rounded(30, .bold))
                .foregroundStyle(Theme.ink)
            Text("Everything you need to train your whole pack \u{2014} for one fair price.")
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
    }

    private var featureList: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(Pro.features.enumerated()), id: \.offset) { _, feature in
                    HStack(spacing: 14) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Theme.accent.opacity(0.12)))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.title)
                                .font(Theme.rounded(16, .bold))
                                .foregroundStyle(Theme.ink)
                            Text(feature.detail)
                                .font(Theme.rounded(13))
                                .foregroundStyle(Theme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(feature.title). \(feature.detail)")
                }
            }
        }
    }

    private var priceCard: some View {
        VStack(spacing: 4) {
            Text(Pro.priceLabel)
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
            Text("One-time \u{2022} no subscription \u{2022} free updates")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .fill(Theme.accent.opacity(0.1))
        )
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            Button {
                unlock()
            } label: {
                Text(isPro ? "Pro unlocked" : "Unlock Fetch Pro")
            }
            .buttonStyle(PrimaryButtonStyle(enabled: !isPro))
            .disabled(isPro)

            Button("Restore purchase") {
                // Simulated restore: if a prior purchase existed, isPro would already be true.
                Haptics.selection(enabled: settings.hapticsEnabled)
                if isPro { dismiss() }
            }
            .font(Theme.rounded(15, .semibold))
            .foregroundStyle(Theme.accent)

            Button("Maybe later") { dismiss() }
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private var footnote: some View {
        Text("Simulated purchase for this build. The gating logic is StoreKit-ready \u{2014} drop in a product and transaction listener to ship.")
            .font(Theme.rounded(11))
            .foregroundStyle(Theme.inkSoft)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 10)
    }

    private func unlock() {
        guard !isPro else { return }
        isPro = true
        Haptics.success(enabled: settings.hapticsEnabled)
        withAnimation(reduceMotion ? nil : .spring(response: 0.4)) { unlocked = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            dismiss()
        }
    }
}
