import SwiftUI

/// A tasteful simulated paywall for Quotient Pro ($2.99 one-time). Unlock is
/// simulated by flipping the persisted `isPro` flag — no real transaction.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPro") private var isPro = false
    @State private var purchasing = false

    private let features: [(icon: String, title: String, detail: String)] = [
        ("square.grid.4x3.fill", "6×6 & 7×7 grids", "Unlock Hard and Expert puzzles."),
        ("infinity", "Unlimited puzzles", "Generate as many fresh boards as you like."),
        ("calendar.badge.clock", "Daily archive", "Replay every past daily puzzle."),
        ("paintpalette.fill", "Extra themes", "Personalize with new accent colors.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header

                    VStack(spacing: 12) {
                        ForEach(features, id: \.title) { feature in
                            featureRow(feature)
                        }
                    }

                    if isPro {
                        Label("Quotient Pro is active", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(Theme.success)
                            .padding(.top, 8)
                    } else {
                        VStack(spacing: 10) {
                            Button {
                                simulatePurchase()
                            } label: {
                                if purchasing {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Unlock Pro · $2.99")
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(purchasing)

                            Text("One-time purchase. No ads, ever.")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(22)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Quotient Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isPro ? "Done" : "Not Now") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Theme.accent.opacity(0.14))
                    .frame(width: 92, height: 92)
                Image(systemName: "crown.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text("Go ad-free, forever")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Quotient Pro is a one-time unlock that opens every grid size and the full daily archive.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func featureRow(_ feature: (icon: String, title: String, detail: String)) -> some View {
        HStack(spacing: 14) {
            Image(systemName: feature.icon)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 34)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(feature.detail)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
        .accessibilityElement(children: .combine)
    }

    private func simulatePurchase() {
        purchasing = true
        // Simulate a brief store round-trip, then unlock.
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            await MainActor.run {
                isPro = true
                purchasing = false
            }
        }
    }
}
