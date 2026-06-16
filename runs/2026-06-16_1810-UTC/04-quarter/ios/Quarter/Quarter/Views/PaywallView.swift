import SwiftUI

/// Tasteful, simulated paywall for Quarter Pro ($5.99 one-time).
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let features: [(icon: String, title: String, detail: String)] = [
        ("square.on.square", "Unlimited scenarios", "Save and compare as many what-if plans as you like."),
        ("arrow.left.arrow.right", "Side-by-side compare", "See which plan owes less and the exact delta."),
        ("calendar.badge.clock", "Quarterly tracking", "Mark each quarter paid and watch your progress."),
        ("calendar", "Multi-year", "Switch between 2024 and 2025 figures."),
        ("square.and.arrow.up", "CSV export", "Export your ledger as a clean, standards-compliant file.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.l) {
                    header
                    featureList
                    purchaseSection
                    finePrint
                }
                .padding(Theme.Spacing.l)
            }
            .background(Theme.background)
            .navigationTitle("Quarter Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: store.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.14))
                    .frame(width: 96, height: 96)
                Image(systemName: "seal.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text("Unlock everything, once")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text("A single \(StoreManager.priceString) purchase. No subscription, ever.")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    private var featureList: some View {
        VStack(spacing: Theme.Spacing.m) {
            ForEach(Array(features.enumerated()), id: \.offset) { _, feature in
                HStack(spacing: Theme.Spacing.m) {
                    Image(systemName: feature.icon)
                        .font(.title3)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 32)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.headline)
                        Text(feature.detail)
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    Spacer()
                }
                .accessibilityElement(children: .combine)
            }
        }
        .card()
    }

    private var purchaseSection: some View {
        VStack(spacing: Theme.Spacing.m) {
            if store.isPro {
                Label("You have Quarter Pro", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
            } else {
                Button {
                    Task { await store.purchase() }
                } label: {
                    if store.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Unlock Pro · \(StoreManager.priceString)")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(store.isPurchasing)

                Button("Restore purchase") {
                    Task { await store.restore() }
                }
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private var finePrint: some View {
        Text("Simulated purchase for this demo build — no real charge is made. Quarter remains an educational estimate and is not tax advice.")
            .font(.caption2)
            .foregroundStyle(Theme.tertiaryText)
            .multilineTextAlignment(.center)
    }
}
