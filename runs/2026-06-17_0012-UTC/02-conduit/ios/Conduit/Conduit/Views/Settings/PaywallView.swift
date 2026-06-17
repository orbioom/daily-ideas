import SwiftUI

/// One-time Conduit Pro purchase screen. StoreKit-ready in spirit; the demo unlock
/// and restore both simply set the persisted `isPro` flag.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage("isPro") private var isPro: Bool = false

    @State private var showRestoredNote = false

    private let price = "$2.99"

    private let perks: [(String, String)] = [
        ("crown.fill", "Master & Mind-bender packs (8×8 and 9×9)"),
        ("calendar.badge.clock", "Daily archive — replay past days"),
        ("eye.fill", "Color-blind palette with letter labels"),
        ("chart.line.uptrend.xyaxis", "Full stats: trend & board-size charts")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    perksCard
                    if isPro {
                        activeState
                    } else {
                        purchaseButtons
                    }
                    Text("This is a one-time purchase. The demo unlock and Restore in this build set the Pro flag locally; no payment is taken.")
                        .font(.caption2)
                        .foregroundStyle(ConduitTheme.secondaryText(scheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(20)
            }
            .background(ConduitTheme.appBackground(scheme).ignoresSafeArea())
            .navigationTitle("Conduit Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Purchases restored", isPresented: $showRestoredNote) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Conduit Pro is now unlocked on this device.")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(ConduitTheme.accent.opacity(0.15)).frame(width: 96, height: 96)
                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(ConduitTheme.accent)
            }
            .accessibilityHidden(true)
            Text("Unlock everything").font(.title2.weight(.bold))
                .foregroundStyle(ConduitTheme.primaryText(scheme))
            Text("A single \(price) purchase. No ads, ever.")
                .font(.subheadline)
                .foregroundStyle(ConduitTheme.secondaryText(scheme))
        }
    }

    private var perksCard: some View {
        ConduitCard {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(perks.enumerated()), id: \.offset) { _, perk in
                    HStack(spacing: 12) {
                        Image(systemName: perk.0)
                            .foregroundStyle(ConduitTheme.accent)
                            .frame(width: 26)
                        Text(perk.1)
                            .font(.subheadline)
                            .foregroundStyle(ConduitTheme.primaryText(scheme))
                        Spacer()
                    }
                }
            }
        }
    }

    private var purchaseButtons: some View {
        VStack(spacing: 12) {
            Button("Unlock Pro — \(price)") {
                isPro = true
            }
            .buttonStyle(ConduitPrimaryButtonStyle())

            Button("Restore purchase") {
                isPro = true
                showRestoredNote = true
            }
            .buttonStyle(ConduitSecondaryButtonStyle())
        }
    }

    private var activeState: some View {
        VStack(spacing: 10) {
            Label("Conduit Pro is active", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(ConduitTheme.accent)
            Button("Done") { dismiss() }
                .buttonStyle(ConduitPrimaryButtonStyle())
        }
    }
}
