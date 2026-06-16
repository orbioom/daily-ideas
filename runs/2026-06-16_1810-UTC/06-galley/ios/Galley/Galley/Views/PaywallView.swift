import SwiftUI

/// Simulated one-time purchase of Galley Pro ($2.99). Sets @AppStorage("isPro").
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage(PrefKey.isPro) private var isPro: Bool = false
    @State private var purchasing = false

    private let perks: [(String, String)] = [
        ("infinity", "Unlimited saved recipes"),
        ("timer", "Unlimited concurrent timers"),
        ("arrow.triangle.2.circlepath", "Add your own substitutions"),
        ("scalemass", "Pro metric & imperial extras"),
        ("heart.fill", "Support a small studio")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                GalleyBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        ZStack {
                            Circle().fill(GalleyTheme.terracotta.opacity(0.14)).frame(width: 120, height: 120)
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(GalleyTheme.terracotta)
                        }
                        .accessibilityHidden(true)
                        .padding(.top, 16)

                        VStack(spacing: 6) {
                            Text("Galley Pro")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(GalleyTheme.primaryText(scheme))
                            Text("One-time purchase · $2.99")
                                .font(.headline)
                                .foregroundStyle(GalleyTheme.secondaryText(scheme))
                        }

                        GalleyCard {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(perks, id: \.1) { perk in
                                    HStack(spacing: 12) {
                                        Image(systemName: perk.0)
                                            .foregroundStyle(GalleyTheme.sage)
                                            .frame(width: 26)
                                            .accessibilityHidden(true)
                                        Text(perk.1)
                                            .foregroundStyle(GalleyTheme.primaryText(scheme))
                                        Spacer()
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel(perk.1)
                                }
                            }
                        }

                        if isPro {
                            Label("You own Galley Pro. Thank you!", systemImage: "checkmark.seal.fill")
                                .font(.headline)
                                .foregroundStyle(GalleyTheme.sageDeep)
                        } else {
                            Button {
                                purchase()
                            } label: {
                                Text(purchasing ? "Unlocking…" : "Unlock Galley Pro · $2.99")
                            }
                            .buttonStyle(GalleyPrimaryButtonStyle())
                            .disabled(purchasing)

                            Text("Simulated purchase for this demo. No charge is made.")
                                .font(.caption)
                                .foregroundStyle(GalleyTheme.secondaryText(scheme))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func purchase() {
        purchasing = true
        // Simulate a brief unlock; no real StoreKit transaction.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isPro = true
            purchasing = false
            Haptics.success()
            dismiss()
        }
    }
}
