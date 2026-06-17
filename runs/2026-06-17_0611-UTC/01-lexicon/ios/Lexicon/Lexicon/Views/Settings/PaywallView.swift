import SwiftUI

/// Simulated one-time purchase of Lexicon Pro ($2.99). Sets @AppStorage("isPro").
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage(PrefKey.isPro) private var isPro: Bool = false
    @State private var purchasing = false

    private let perks: [(String, String)] = [
        ("calendar", "Full puzzle archive — replay any past day"),
        ("textformat.size", "6-letter words & future length packs"),
        ("eye.fill", "High-contrast themes for every state"),
        ("infinity", "Keeps unlimited daily & practice free forever"),
        ("heart.fill", "Support a small, ad-free studio")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LexBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        ZStack {
                            Circle().fill(LexTheme.green.opacity(0.14)).frame(width: 120, height: 120)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 54))
                                .foregroundStyle(LexTheme.green)
                        }
                        .accessibilityHidden(true)
                        .padding(.top, 16)

                        VStack(spacing: 6) {
                            Text("Lexicon Pro")
                                .font(LexTheme.display(30, weight: .bold))
                                .foregroundStyle(LexTheme.primaryText(scheme))
                            Text("One-time purchase · $2.99")
                                .font(.headline)
                                .foregroundStyle(LexTheme.secondaryText(scheme))
                        }

                        LexCard {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(perks, id: \.1) { perk in
                                    HStack(spacing: 12) {
                                        Image(systemName: perk.0)
                                            .foregroundStyle(LexTheme.green)
                                            .frame(width: 26)
                                            .accessibilityHidden(true)
                                        Text(perk.1)
                                            .foregroundStyle(LexTheme.primaryText(scheme))
                                        Spacer()
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel(perk.1)
                                }
                            }
                        }

                        if isPro {
                            Label("You own Lexicon Pro. Thank you!", systemImage: "checkmark.seal.fill")
                                .font(.headline)
                                .foregroundStyle(LexTheme.greenDeep)
                        } else {
                            Button {
                                purchase()
                            } label: {
                                Text(purchasing ? "Unlocking…" : "Unlock Lexicon Pro (demo) · $2.99")
                            }
                            .buttonStyle(LexPrimaryButtonStyle())
                            .disabled(purchasing)

                            Button("Restore Purchase") { restore() }
                                .buttonStyle(LexSecondaryButtonStyle())
                                .disabled(purchasing)

                            Text("Simulated purchase for this demo. No charge is made.")
                                .font(.caption)
                                .foregroundStyle(LexTheme.secondaryText(scheme))
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
        purchasing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isPro = true
            purchasing = false
            Haptics.success()
            dismiss()
        }
    }
}
