import SwiftUI

/// A calm, honest one-time-purchase paywall. No countdowns, no dark patterns.
/// The "purchase" simply flips a persisted flag (mock — no StoreKit here).
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage(PrefKey.isPro) private var isPro = false
    @AppStorage(PrefKey.hapticsEnabled) private var haptics = true

    private let perks: [(String, String)] = [
        ("person.2.fill", "Unlimited baby profiles"),
        ("square.and.arrow.up", "Export your logs as a summary"),
        ("paintpalette.fill", "All profile colors & themes"),
        ("heart.fill", "Support a tiny indie studio")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ambientGradient(scheme).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 22) {
                        ZStack {
                            Circle().fill(Theme.accentGradient).frame(width: 96, height: 96)
                            Image(systemName: "sparkles")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundStyle(.white)
                                .accessibilityHidden(true)
                        }
                        .padding(.top, 8)

                        VStack(spacing: 6) {
                            Text("Sprig Pro")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(Theme.primaryText(scheme))
                            Text("A one-time unlock — no subscription, ever.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.secondaryText(scheme))
                                .multilineTextAlignment(.center)
                        }

                        VStack(spacing: 12) {
                            ForEach(perks, id: \.1) { perk in
                                HStack(spacing: 14) {
                                    Image(systemName: perk.0)
                                        .font(.headline)
                                        .foregroundStyle(Theme.accent)
                                        .frame(width: 28)
                                        .accessibilityHidden(true)
                                    Text(perk.1)
                                        .foregroundStyle(Theme.primaryText(scheme))
                                    Spacer()
                                }
                            }
                        }
                        .padding(18)
                        .background(Theme.card(scheme), in: RoundedRectangle(cornerRadius: Theme.corner))

                        if isPro {
                            Label("You already have Pro", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Theme.accent)
                                .font(.headline)
                        } else {
                            PrimaryButton(title: "Unlock for $4.99", systemImage: "lock.open.fill") {
                                isPro = true
                                Haptics.success(haptics)
                            }
                            Text("Restoring a previous purchase? Tap below.")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText(scheme))
                            Button("Restore purchase") {
                                isPro = true
                                Haptics.success(haptics)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: isPro) { _, pro in
                if pro { dismiss() }
            }
        }
    }
}
