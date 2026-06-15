import SwiftUI

struct PaywallView: View {
    let reason: PaywallReason
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var unlocked = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    WrenBirdView(mood: .thriving, accessory: "scarf")
                        .frame(width: 130, height: 130)
                        .padding(.top, 12)

                    VStack(spacing: 8) {
                        Text(reason.title)
                            .font(Theme.serif(28, .bold))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                        Text(reason.message)
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Pro.perks, id: \.self) { perk in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.good)
                                Text(perk)
                                    .font(Theme.rounded(15))
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .card(Theme.surface)

                    VStack(spacing: 6) {
                        Text("\(Pro.productName) — \(Pro.priceLabel)")
                            .font(Theme.rounded(18, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("One-time purchase. No subscription, ever.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }

                    VStack(spacing: 10) {
                        Button(settings.isPro ? "Pro is active" : "Unlock for \(Pro.priceLabel)") {
                            unlock()
                        }
                        .buttonStyle(WrenPrimaryButtonStyle())
                        .disabled(settings.isPro)

                        Button("Restore purchase") { restore() }
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(.horizontal)

                    Text("This demo unlocks Pro locally. Production wires StoreKit 2 here.")
                        .font(Theme.rounded(11))
                        .foregroundStyle(Theme.inkFaint)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 12)
                }
                .padding(.horizontal)
            }
            .background(Theme.bg)
            .navigationTitle("Wren Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .overlay {
                if unlocked {
                    unlockedOverlay
                }
            }
        }
    }

    private var unlockedOverlay: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.good)
                Text("Wren Pro unlocked")
                    .font(Theme.rounded(20, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Thank you for supporting calm software.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(28)
            .card(Theme.surface)
            .padding(40)
        }
        .transition(.opacity)
        .accessibilityAddTraits(.isModal)
    }

    private func unlock() {
        settings.isPro = true
        settings.haptic(.success)
        withAnimation { unlocked = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            dismiss()
        }
    }

    private func restore() {
        // Simulated restore: in production this calls StoreKit's restore flow.
        settings.haptic(.soft)
        if settings.isPro {
            dismiss()
        } else {
            // Nothing to restore in the local demo; reflect Pro as not yet purchased.
            settings.isPro = true
            withAnimation { unlocked = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { dismiss() }
        }
    }
}
