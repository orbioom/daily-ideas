import SwiftUI

/// Simulated one-time Pro unlock (StoreKit-ready). Sets `isPro = true` on purchase.
struct PaywallView: View {
    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var purchased = false

    var body: some View {
        ZStack {
            Theme.heroGradient.ignoresSafeArea()
            StarfieldBackground(reduceMotion: reduceMotion).ignoresSafeArea().accessibilityHidden(true)

            ScrollView {
                VStack(spacing: 22) {
                    header
                    perks
                    purchaseButtons
                    footnote
                }
                .padding(24)
            }
            .scrollIndicators(.hidden)

            if purchased {
                VStack { Spacer(); SuccessToast(text: "Lodestar Pro unlocked"); Spacer().frame(height: 60) }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(Theme.gold)
                .shadow(color: Theme.gold.opacity(0.6), radius: 18)
                .accessibilityHidden(true)
            Text("Lodestar Pro")
                .font(Theme.rounded(30, .bold))
                .foregroundStyle(.white)
            Text("One fair price. Yours forever. No subscription, no account.")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
        .accessibilityElement(children: .combine)
    }

    private var perks: some View {
        VStack(spacing: 12) {
            ForEach(Pro.perks) { perk in
                HStack(spacing: 14) {
                    Image(systemName: perk.symbol)
                        .font(.title3)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 30)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(perk.title).font(Theme.rounded(16, .semibold)).foregroundStyle(.white)
                        Text(perk.detail).font(.caption).foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: Theme.corner).fill(.white.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: Theme.corner).strokeBorder(.white.opacity(0.1), lineWidth: 0.6))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(perk.title). \(perk.detail)")
            }
        }
    }

    private var purchaseButtons: some View {
        VStack(spacing: 10) {
            Button {
                purchase()
            } label: {
                Text(isPro ? "Pro is active" : "Unlock \(Pro.productName) — \(Pro.priceLabel)")
                    .font(Theme.rounded(17, .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Theme.accent))
                    .foregroundStyle(Color(hex: 0x05070E))
            }
            .disabled(isPro)

            Button("Restore purchase") { purchase() }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))

            Button("Maybe later") { dismiss() }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(.top, 6)
    }

    private var footnote: some View {
        Text("Simulated purchase for this build (StoreKit-ready). The free experience — Tonight, the live sky map and basic search — stays fully usable.")
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.5))
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }

    private func purchase() {
        guard !isPro else { dismiss(); return }
        isPro = true
        Haptics.success(settings.hapticsEnabled)
        withAnimation { purchased = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            dismiss()
        }
    }
}
