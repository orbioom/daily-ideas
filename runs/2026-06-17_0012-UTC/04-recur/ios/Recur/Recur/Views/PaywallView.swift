import SwiftUI

struct PaywallView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PrefKey.isPro) private var isPro: Bool = false

    private struct Feature: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let body: String
    }

    private let features: [Feature] = [
        Feature(symbol: "infinity", title: "Unlimited subscriptions",
                body: "Track every recurring payment — past the \(FreeTier.maxSubscriptions)-subscription free limit."),
        Feature(symbol: "bell.badge", title: "Renewal & trial reminders",
                body: "On-device notifications before each renewal and before any free trial ends."),
        Feature(symbol: "chart.bar.xaxis", title: "Full insights & calendar",
                body: "Spend by category and cycle, a renewal calendar, and projected spending."),
        Feature(symbol: "chart.xyaxis.line", title: "Price-history logging",
                body: "Log every price hike and see the trend on a sparkline."),
        Feature(symbol: "square.and.arrow.up", title: "CSV export",
                body: "Export all your subscriptions to a spreadsheet, any time.")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                RecurTheme.appBackground(scheme).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 22) {
                        header
                        VStack(spacing: 14) {
                            ForEach(features) { feature in
                                featureRow(feature)
                            }
                        }
                        .padding(.horizontal, 4)
                        purchaseArea
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Recur Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close")
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(RecurTheme.violet.opacity(0.14)).frame(width: 96, height: 96)
                Image(systemName: "crown.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(RecurTheme.violet)
            }
            .accessibilityHidden(true)
            Text("Unlock everything, once")
                .font(.title2.weight(.bold))
                .foregroundStyle(RecurTheme.primaryText(scheme))
                .multilineTextAlignment(.center)
            Text("A one-time purchase. No subscription to track your subscriptions — and nothing leaves your device.")
                .font(.subheadline)
                .foregroundStyle(RecurTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
        }
    }

    private func featureRow(_ feature: Feature) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: feature.symbol)
                .font(.title3)
                .foregroundStyle(RecurTheme.violet)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RecurTheme.primaryText(scheme))
                Text(feature.body)
                    .font(.caption)
                    .foregroundStyle(RecurTheme.secondaryText(scheme))
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var purchaseArea: some View {
        VStack(spacing: 12) {
            if isPro {
                Label("Recur Pro is active", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(RecurTheme.teal)
                    .padding(.vertical, 8)
                Button("Done") { dismiss() }
                    .buttonStyle(RecurSecondaryButtonStyle())
            } else {
                Button {
                    Haptics.success()
                    isPro = true
                } label: {
                    VStack(spacing: 2) {
                        Text("Unlock Recur Pro")
                        Text("$3.99 · one-time")
                            .font(.caption)
                            .opacity(0.9)
                    }
                }
                .buttonStyle(RecurPrimaryButtonStyle())

                Button("Restore Purchase") {
                    // In a real build this calls StoreKit; here it restores the demo entitlement.
                    Haptics.light()
                    isPro = true
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RecurTheme.violet)

                Text("Demo build: unlock and restore are simulated locally.")
                    .font(.caption2)
                    .foregroundStyle(RecurTheme.secondaryText(scheme))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 4)
    }
}
