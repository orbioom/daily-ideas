import SwiftUI

/// Simulated one-time Pro unlock. No real StoreKit — `unlock()` flips the @AppStorage flag.
struct PaywallView: View {
    @EnvironmentObject private var pro: ProStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        header
                        benefits
                        unlockButton
                        secondaryButtons
                        disclaimer
                    }
                    .padding(22)
                }
            }
            .navigationTitle("Pangram Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Hexagon().fill(Theme.heroGradient).frame(width: 96, height: 96)
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
            Text("Unlock everything")
                .font(Theme.rounded(26, .heavy))
                .foregroundStyle(Theme.ink)
            Text("A one-time purchase. The Daily and your first few practice puzzles each day are always free.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
    }

    private var benefits: some View {
        VStack(spacing: 12) {
            ForEach(ProBenefit.all) { benefit in
                SectionCard {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: benefit.symbol)
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(benefit.title)
                                .font(Theme.rounded(16, .bold))
                                .foregroundStyle(Theme.ink)
                            Text(benefit.detail)
                                .font(Theme.rounded(14))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var unlockButton: some View {
        Button {
            pro.unlock()
            Haptics.notify(.success, enabled: settings.hapticsEnabled)
            dismiss()
        } label: {
            VStack(spacing: 2) {
                Text("Unlock Pangram Pro")
                    .font(Theme.rounded(18, .bold))
                Text("\(pro.priceLabel) · one-time")
                    .font(Theme.rounded(13, .medium))
                    .opacity(0.9)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Capsule().fill(Theme.accent))
        }
        .accessibilityHint("Unlocks all Pro features")
    }

    private var secondaryButtons: some View {
        VStack(spacing: 10) {
            Button {
                let ok = pro.restore()
                restoreMessage = ok ? "Pro restored." : "No previous purchase found."
            } label: {
                Text("Restore purchase")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.accentDeep)
            }
            if let restoreMessage {
                Text(restoreMessage)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            Button {
                dismiss()
            } label: {
                Text("Maybe later")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private var disclaimer: some View {
        Text("This build simulates the purchase (no charge). The flow is StoreKit-ready for production.")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkSoft)
            .multilineTextAlignment(.center)
    }
}
