import SwiftUI

/// Honest one-time "Unlock Nonet Pro" screen with a demo note + Restore.
struct PaywallView: View {
    let reason: PaywallReason
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Pro.storageKey) private var isPro = false

    private let benefits: [(String, String)] = [
        ("flame.fill", "Hard & Expert puzzles, unlimited"),
        ("lightbulb.fill", "Unlimited logical hints with explanations"),
        ("paintpalette.fill", "Extra board themes"),
        ("chart.bar.xaxis", "Full stats history across every difficulty"),
        ("checkmark.seal.fill", "Never any ads — one-time, not a subscription"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        Circle().fill(Theme.accent.opacity(0.12)).frame(width: 96, height: 96)
                        Image(systemName: "seal.fill")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityHidden(true)
                    .padding(.top, 12)

                    Text(reason.title)
                        .font(Theme.rounded(26, .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(reason.blurb)
                        .font(Theme.rounded(16))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    CardView {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(Array(benefits.enumerated()), id: \.offset) { _, b in
                                HStack(spacing: 12) {
                                    Image(systemName: b.0)
                                        .foregroundStyle(Theme.accent)
                                        .frame(width: 26)
                                    Text(b.1)
                                        .font(Theme.rounded(15))
                                        .foregroundStyle(Theme.textPrimary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    if isPro {
                        Label("Nonet Pro is unlocked. Thank you!", systemImage: "checkmark.circle.fill")
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.success)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 10) {
                            Button("Unlock Nonet Pro — \(Pro.price)") {
                                isPro = true
                            }
                            .buttonStyle(PrimaryButtonStyle())

                            Button("Restore Purchase") {
                                // Demo restore: re-applies the local flag if previously bought.
                                isPro = UserDefaults.standard.bool(forKey: Pro.storageKey)
                            }
                            .font(Theme.rounded(15, .medium))
                            .foregroundStyle(Theme.accent)
                        }
                        .padding(.horizontal)
                    }

                    Text("Demo build: this is a local one-time unlock with no real payment. In the shipping app this would be a StoreKit non-consumable purchase.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 4)

                    Spacer(minLength: 12)
                }
                .padding(.bottom, 24)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Nonet Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isPro ? "Done" : "Not Now") { dismiss() }
                }
            }
        }
    }
}
