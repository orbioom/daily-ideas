import SwiftUI

/// Honest one-time-unlock paywall. Backed by @AppStorage("isPro") for this build;
/// clearly labeled as a local unlock that production would wire to StoreKit 2.
struct PaywallView: View {
    @AppStorage("isPro") private var isPro = false
    @Environment(\.dismiss) private var dismiss

    private let benefits: [(String, String, String)] = [
        ("infinity", "Unlimited reviews", "No daily cap — study as much as you like."),
        ("books.vertical.fill", "Full SAT & GRE banks", "Every advanced word, not just the everyday tier."),
        ("square.grid.2x2.fill", "All quiz modes", "Synonym match and typed fill-in-the-blank."),
        ("chart.bar.xaxis", "Complete statistics", "Every chart, forecast, and trend unlocked."),
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    header
                    VStack(spacing: 12) {
                        ForEach(benefits, id: \.0) { b in
                            benefitRow(icon: b.0, title: b.1, detail: b.2)
                        }
                    }
                    .padding(.horizontal, 18)

                    VStack(spacing: 10) {
                        if isPro {
                            Label("Lexeme Pro is active", systemImage: "checkmark.seal.fill")
                                .font(Theme.rounded(16, .semibold))
                                .foregroundStyle(Theme.good)
                                .padding(.vertical, 8)
                        } else {
                            PrimaryButton(title: "Unlock Lexeme Pro  $5.99", systemImage: "sparkles") {
                                Haptics.success()
                                isPro = true
                            }
                            Button("Restore purchase") {
                                isPro = true
                                Haptics.success()
                            }
                            .font(Theme.rounded(14, .medium))
                            .foregroundStyle(Theme.accent)
                        }

                        Text("One-time purchase. No subscription, no ads, ever.")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                        Text("Demo build: unlocks locally on this device; production wires StoreKit 2.")
                            .font(Theme.rounded(11))
                            .foregroundStyle(Theme.inkFaint)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 28)
                }
                .padding(.top, 8)
            }

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Theme.inkFaint)
                            .padding(16)
                    }
                    .accessibilityLabel("Close")
                }
                Spacer()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.gold.opacity(0.16)).frame(width: 96, height: 96)
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.gold)
                    .accessibilityHidden(true)
            }
            .padding(.top, 28)
            Text("Lexeme Pro")
                .font(Theme.serif(30, .bold))
                .foregroundStyle(Theme.ink)
            Text("The whole lexicon, unlocked once and yours for good.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
    }

    private func benefitRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Theme.accent)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                Text(detail).font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.hairline))
    }
}
