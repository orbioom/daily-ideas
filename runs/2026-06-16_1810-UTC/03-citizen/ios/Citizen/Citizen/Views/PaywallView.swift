import SwiftUI

/// Tasteful simulated paywall for Citizen Pro ($4.99 one-time). Unlocks via
/// @AppStorage("isPro"); no real StoreKit (studio simulation).
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppPreferences.self) private var prefs
    @Environment(\.colorScheme) private var scheme

    @State private var purchasing = false

    private let benefits: [(String, String)] = [
        ("infinity", "Unlimited mock exams every day"),
        ("square.grid.2x2", "All categories + by-category study"),
        ("scope", "Weak-area adaptive practice"),
        ("textformat.abc", "Full reading & writing vocabulary + practice"),
        ("speaker.wave.2", "Audio narration (read-aloud)"),
        ("chart.bar", "Full progress analytics"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    benefitList
                    if prefs.isPro {
                        activeBlock
                    } else {
                        purchaseBlock
                    }
                    Text("Simulated purchase for this studio build. No charge is made.")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary(scheme))
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .screenBackground(scheme)
            .navigationTitle("Citizen Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.gold)
                .accessibilityHidden(true)
            Text("Go all-in on your citizenship test")
                .font(Theme.title)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textPrimary(scheme))
            Text("One payment. Yours forever. No subscriptions.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary(scheme))
        }
        .padding(.top, 8)
    }

    private var benefitList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(benefits, id: \.1) { benefit in
                HStack(spacing: 14) {
                    Image(systemName: benefit.0)
                        .font(.title3)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 30)
                        .accessibilityHidden(true)
                    Text(benefit.1)
                        .font(.body)
                        .foregroundStyle(Theme.textPrimary(scheme))
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .cardSurface()
    }

    private var purchaseBlock: some View {
        VStack(spacing: 12) {
            Button {
                purchase()
            } label: {
                HStack {
                    if purchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Unlock Pro \u{2014} $4.99")
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(purchasing)

            Button("Restore purchase") {
                purchase()
            }
            .font(.subheadline)
            .foregroundStyle(Theme.accent)
        }
    }

    private var activeBlock: some View {
        VStack(spacing: 8) {
            Label("Citizen Pro is active", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(Theme.success(scheme))
            Text("Thank you for supporting Citizen. Every feature is unlocked.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary(scheme))
            Button("Reset to free (debug)") {
                prefs.isPro = false
            }
            .font(.caption)
            .foregroundStyle(Theme.textSecondary(scheme))
            .padding(.top, 4)
        }
        .cardSurface()
    }

    private func purchase() {
        guard !purchasing else { return }
        purchasing = true
        Haptics.light(enabled: prefs.hapticsEnabled)
        Task { @MainActor in
            // Simulate a brief transaction.
            try? await Task.sleep(nanoseconds: 700_000_000)
            prefs.isPro = true
            purchasing = false
            Haptics.success(enabled: prefs.hapticsEnabled)
            dismiss()
        }
    }
}
