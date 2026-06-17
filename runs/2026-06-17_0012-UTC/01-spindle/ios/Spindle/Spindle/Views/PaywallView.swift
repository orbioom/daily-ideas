import SwiftUI

/// Simulated one-time purchase of Spindle Pro ($2.99). Sets @AppStorage("isPro").
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage(PrefKey.isPro) private var isPro: Bool = false
    @State private var purchasing = false

    private let perks: [(String, String)] = [
        ("suit.club.fill", "4-suit mode (the real challenge)"),
        ("calendar", "Daily-deal archive (replay any day)"),
        ("paintpalette", "Extra felt themes: Sapphire & Wine"),
        ("chart.bar.fill", "Full stats history, not just recent"),
        ("heart.fill", "Support a small studio")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                SpindleBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        ZStack {
                            Circle().fill(SpindleTheme.emerald.opacity(0.14)).frame(width: 120, height: 120)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(SpindleTheme.gold)
                        }
                        .accessibilityHidden(true)
                        .padding(.top, 16)

                        VStack(spacing: 6) {
                            Text("Spindle Pro")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(SpindleTheme.primaryText(scheme))
                            Text("One-time purchase · $2.99")
                                .font(.headline)
                                .foregroundStyle(SpindleTheme.secondaryText(scheme))
                        }

                        SpindleCard {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(perks, id: \.1) { perk in
                                    HStack(spacing: 12) {
                                        Image(systemName: perk.0)
                                            .foregroundStyle(SpindleTheme.emerald)
                                            .frame(width: 26)
                                            .accessibilityHidden(true)
                                        Text(perk.1)
                                            .foregroundStyle(SpindleTheme.primaryText(scheme))
                                        Spacer()
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel(perk.1)
                                }
                            }
                        }

                        if isPro {
                            Label("You own Spindle Pro. Thank you!", systemImage: "checkmark.seal.fill")
                                .font(.headline)
                                .foregroundStyle(SpindleTheme.emeraldDeep)
                        } else {
                            Button {
                                purchase()
                            } label: {
                                Text(purchasing ? "Unlocking…" : "Unlock Spindle Pro · $2.99")
                            }
                            .buttonStyle(SpindlePrimaryButtonStyle())
                            .disabled(purchasing)

                            Button("Restore Purchase") { restore() }
                                .buttonStyle(SpindleSecondaryButtonStyle())
                                .disabled(purchasing)

                            Text("Simulated purchase for this demo. No charge is made.")
                                .font(.caption)
                                .foregroundStyle(SpindleTheme.secondaryText(scheme))
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isPro = true
            purchasing = false
            Haptics.success()
            dismiss()
        }
    }

    private func restore() {
        // Demo restore: in a real build this would query StoreKit transactions.
        purchasing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isPro = true
            purchasing = false
            Haptics.success()
            dismiss()
        }
    }
}
