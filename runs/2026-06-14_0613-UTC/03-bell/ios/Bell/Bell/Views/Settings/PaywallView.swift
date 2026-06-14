import SwiftUI

/// Honest one-time unlock. This is a demo: tapping "Unlock" flips the local
/// `isPro` flag — a real build would route this through StoreKit 2.
struct PaywallView: View {
    let reason: Pro.Reason

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @State private var restoredEmpty = false

    private let perks: [(String, String)] = [
        ("bell", "All bells — chime & gong"),
        ("water.waves", "All soundscapes — rain, ocean, drone"),
        ("infinity", "Unlimited custom presets"),
        ("chart.bar.xaxis", "Full insights, forever")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        Text(reason.title)
                            .font(Theme.serif(28, .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                        Text(reason.detail)
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)

                    Card {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(Array(perks.enumerated()), id: \.offset) { _, perk in
                                HStack(spacing: 12) {
                                    Image(systemName: perk.0)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Theme.accent)
                                        .frame(width: 26)
                                    Text(perk.1)
                                        .font(Theme.rounded(15))
                                        .foregroundStyle(Theme.textPrimary)
                                }
                            }
                        }
                    }

                    VStack(spacing: 10) {
                        if isPro {
                            Label("Bell Pro is unlocked", systemImage: "checkmark.seal.fill")
                                .font(Theme.rounded(16, .semibold))
                                .foregroundStyle(Theme.accent)
                        } else {
                            PrimaryButton(title: "Unlock Bell Pro · \(Pro.price)") {
                                isPro = true
                                Haptics.success(enabled: settings.hapticsEnabled)
                            }
                            Button("Restore purchase") {
                                // No prior purchase in this demo build.
                                restoredEmpty = true
                            }
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.textSecondary)
                        }
                        Text("One-time purchase. No subscription, no ads.")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.textTertiary)
                        Text("Demo build: unlock flips a local flag instead of charging.")
                            .font(Theme.rounded(11))
                            .foregroundStyle(Theme.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(Theme.spacing)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Nothing to restore", isPresented: $restoredEmpty) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("No previous Bell Pro purchase was found on this device.")
            }
        }
    }
}
