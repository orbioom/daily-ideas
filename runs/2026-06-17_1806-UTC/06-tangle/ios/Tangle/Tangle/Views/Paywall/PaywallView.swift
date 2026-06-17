import SwiftUI

/// Simulated one-time Pro unlock. StoreKit-ready: replace `unlock`/`restore`
/// bodies with real StoreKit calls without changing the UI.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @State private var restoreNote: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    unlocksList
                    priceAndActions
                    Text("Simulated purchase for this build — StoreKit-ready, no charge.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Tangle Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .alert("Restore", isPresented: Binding(
                get: { restoreNote != nil },
                set: { if !$0 { restoreNote = nil } }
            )) {
                Button("OK", role: .cancel) { restoreNote = nil }
            } message: {
                Text(restoreNote ?? "")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Theme.star)
                .accessibilityHidden(true)
            Text("Unlock the whole garden")
                .font(Theme.rounded(24, .heavy))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("One purchase. Every puzzle. Forever calm.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.top, 8)
    }

    private var unlocksList: some View {
        VStack(spacing: 12) {
            ForEach(Pro.unlocks, id: \.self) { unlock in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    Text(unlock)
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous).fill(Theme.surface).overlay(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1)))
    }

    private var priceAndActions: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Text(Pro.priceLabel)
                    .font(Theme.rounded(30, .heavy))
                    .foregroundStyle(Theme.ink)
                Text("one-time")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            PrimaryButton(title: isPro ? "Pro Unlocked" : "Unlock Tangle Pro", systemImage: isPro ? "checkmark" : "lock.open.fill") {
                unlock()
            }
            .disabled(isPro)
            .opacity(isPro ? 0.7 : 1)

            Button("Restore Purchases") { restore() }
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.accentDeep)

            SecondaryButton(title: "Maybe later") { dismiss() }
        }
    }

    private func unlock() {
        guard !isPro else { return }
        isPro = true
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func restore() {
        if isPro {
            restoreNote = "Your Tangle Pro purchase is already active."
        } else {
            restoreNote = "No previous purchase was found on this device."
        }
    }
}
