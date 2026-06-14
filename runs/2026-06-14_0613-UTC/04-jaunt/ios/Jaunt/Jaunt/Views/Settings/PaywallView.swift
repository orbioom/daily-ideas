import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPro") private var isPro = false
    let reason: PaywallReason

    private struct Feature: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let detail: String
    }

    private let features: [Feature] = [
        Feature(symbol: "infinity", title: "Unlimited trips", detail: "Plan as many jaunts as you like."),
        Feature(symbol: "square.stack.3d.up.fill", title: "All packing templates", detail: "Beach, City, Business, Camping, Winter."),
        Feature(symbol: "chart.pie.fill", title: "Budget analytics", detail: "Category breakdowns and insights."),
        Feature(symbol: "square.and.arrow.up", title: "Itinerary export", detail: "Copy a clean text plan to share.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle().fill(Theme.accent.opacity(0.14)).frame(width: 92, height: 92)
                            Image(systemName: "airplane.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(Theme.accent)
                        }
                        .accessibilityHidden(true)
                        Text("Jaunt Pro")
                            .font(Theme.font(.largeTitle, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(reason.headline)
                            .font(Theme.font(.title3, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .multilineTextAlignment(.center)
                        Text(reason.detail)
                            .font(Theme.font(.subheadline))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 12)

                    VStack(spacing: 12) {
                        ForEach(features) { feature in
                            HStack(spacing: 14) {
                                Image(systemName: feature.symbol)
                                    .font(.title3)
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 30)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(feature.title)
                                        .font(Theme.font(.headline))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(feature.detail)
                                        .font(Theme.font(.caption))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.surface))
                    .overlay(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).strokeBorder(Theme.separator, lineWidth: 1))

                    VStack(spacing: 10) {
                        Button {
                            Haptics.success()
                            isPro = true
                            dismiss()
                        } label: {
                            VStack(spacing: 2) {
                                Text("Unlock Jaunt Pro")
                                Text("\(Pro.price) · one-time")
                                    .font(Theme.font(.caption, weight: .medium))
                                    .opacity(0.9)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button("Restore Purchase") {
                            Haptics.tap()
                            // Demo: no real receipts; restore is a no-op unless already unlocked.
                            dismiss()
                        }
                        .font(Theme.font(.subheadline))
                        .foregroundStyle(Theme.accent)

                        Text("Demo only — this unlocks Pro locally with no real payment. A shipping app would use StoreKit.")
                            .font(Theme.font(.caption2))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill") }
                        .foregroundStyle(Theme.textSecondary)
                        .accessibilityLabel("Close")
                }
            }
        }
    }
}
