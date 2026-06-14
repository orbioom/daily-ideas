import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    let reason: PaywallReason

    private let perks: [(String, String)] = [
        ("infinity", "Unlimited library — no 20-game cap"),
        ("chart.bar.fill", "Full Stats: platforms, genres, ratings, trends"),
        ("slider.horizontal.3", "Advanced pick-next filters & weighting"),
        ("square.and.arrow.up", "Export your whole library as text")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        Text(Pro.productName)
                            .font(Theme.rounded(28, .heavy))
                            .foregroundStyle(Theme.text)
                        Text(reason.title)
                            .font(Theme.rounded(17, .semibold))
                            .foregroundStyle(Theme.accent)
                        Text(reason.message)
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                    .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(perks, id: \.0) { perk in
                            HStack(spacing: 12) {
                                Image(systemName: perk.0)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 28)
                                    .accessibilityHidden(true)
                                Text(perk.1)
                                    .font(Theme.rounded(15))
                                    .foregroundStyle(Theme.text)
                            }
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous).strokeBorder(Theme.stroke, lineWidth: 1))

                    VStack(spacing: 10) {
                        Button {
                            unlock()
                        } label: {
                            Text("Unlock Quest Pro — \(Pro.price)")
                                .font(Theme.rounded(17, .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                        }
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
                        .foregroundStyle(.white)

                        Button("Restore Purchase") { restore() }
                            .font(Theme.rounded(15, .medium))
                            .foregroundStyle(Theme.textSecondary)

                        Text("One-time purchase. Demo unlock — no payment is taken; this flips a local flag so you can explore Pro.")
                            .font(Theme.rounded(11))
                            .foregroundStyle(Theme.textFaint)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func unlock() {
        isPro = true
        Haptics.play(.success, enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func restore() {
        // Demo restore: in a shipping app this would query StoreKit.
        isPro = true
        Haptics.play(.success, enabled: settings.hapticsEnabled)
        dismiss()
    }
}
