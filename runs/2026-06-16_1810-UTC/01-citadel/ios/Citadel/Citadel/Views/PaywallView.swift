import SwiftUI

/// Tasteful, StoreKit-ready-in-spirit paywall. A simulated one-time purchase that sets
/// @AppStorage("isPro") = true. No real StoreKit calls.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("isPro") private var isPro = false
    @AppStorage(SettingsKeys.hapticsEnabled) private var hapticsEnabled = true

    @State private var purchasing = false
    @State private var glow = false

    private let benefits: [(String, String)] = [
        ("number.square", "Numbered deals", "Play any of a million classic deals — or replay a friend's."),
        ("arrow.uturn.backward.circle", "Unlimited undo", "Experiment freely. Take back as many moves as you like."),
        ("paintpalette", "Extra felt themes", "Sapphire, burgundy, and slate baize for your table."),
        ("chart.line.uptrend.xyaxis", "Full stats history", "Keep every game forever, not just your latest hands.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    benefitsList
                    purchaseArea
                    Text("A one-time purchase. No subscriptions, no ads, ever.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
            .navigationTitle("Citadel Pro")
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
                Circle()
                    .fill(Theme.gold.opacity(0.18))
                    .frame(width: 96, height: 96)
                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.gold)
                    .scaleEffect(reduceMotion ? 1 : (glow ? 1.05 : 1.0))
            }
            .accessibilityHidden(true)

            Text("Unlock the full table")
                .font(.system(.title2, design: .serif).weight(.bold))
                .multilineTextAlignment(.center)
            Text("Everything in Citadel, calm and complete.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }

    private var benefitsList: some View {
        VStack(spacing: 14) {
            ForEach(Array(benefits.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: item.0)
                        .font(.title3)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 32)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.1)
                            .font(.headline)
                        Text(item.2)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    @ViewBuilder
    private var purchaseArea: some View {
        if isPro {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("You're all set — Citadel Pro is active.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 8)
        } else {
            VStack(spacing: 12) {
                Button {
                    simulatePurchase()
                } label: {
                    HStack {
                        if purchasing {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(purchasing ? "Unlocking…" : "Unlock Citadel Pro · $2.99")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .disabled(purchasing)
                .accessibilityHint("Simulated one-time purchase that unlocks all Pro features")

                Button("Restore Purchase") {
                    simulatePurchase()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .disabled(purchasing)
            }
        }
    }

    private func simulatePurchase() {
        guard !isPro else { return }
        purchasing = true
        // Simulate a brief StoreKit round-trip, then unlock.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isPro = true
            purchasing = false
            Haptics.success(enabled: hapticsEnabled)
        }
    }
}
