import SwiftUI

/// One-time Reveille Pro unlock sheet. Demo unlock sets `isPro=true` (StoreKit wires in for
/// production). Restore is present with an honest note. No subscription, no ads, no nagging.
struct PaywallView: View {
    let reason: PaywallReason
    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showRestoreNote = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: reason.symbol)
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.accent)
                        .padding(.top, 12)
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text(reason.title)
                            .font(Theme.rounded(26, .bold))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                        Text(reason.blurb)
                            .font(Theme.rounded(16))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 8)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Pro.perks, id: \.text) { perk in
                            HStack(spacing: 12) {
                                Image(systemName: perk.symbol)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 26)
                                    .accessibilityHidden(true)
                                Text(perk.text)
                                    .font(Theme.rounded(15))
                                    .foregroundStyle(Theme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                        }
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.surface))

                    VStack(spacing: 10) {
                        PrimaryButton(title: "Unlock Reveille Pro · \(Pro.priceLabel)",
                                      systemImage: "lock.open.fill") {
                            unlock()
                        }
                        Button("Restore Purchase") {
                            Haptics.select(settings.hapticsEnabled)
                            showRestoreNote = true
                        }
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.inkSoft)
                    }

                    Text("Demo unlock for this build — StoreKit purchase wires in for production. One-time, no subscription. No ads, and we'll never nag you to rate or pay after you've unlocked.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    if showRestoreNote {
                        Text("No previous purchase found on this device.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                            .transition(.opacity)
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Reveille Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .animation(.easeInOut, value: showRestoreNote)
        }
    }

    private func unlock() {
        isPro = true
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
