import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var proStore: ProStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    VStack(spacing: 14) {
                        ForEach(proStore.unlocks) { unlock in
                            unlockRow(unlock)
                        }
                    }
                    .padding(.horizontal, 4)

                    VStack(spacing: 12) {
                        Button {
                            Haptics.success(enabled: settings.hapticsEnabled)
                            proStore.unlock()
                            dismiss()
                        } label: {
                            Text("Unlock Caliper Pro · \(proStore.priceLabel)")
                                .font(Theme.rounded(17, .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .accessibilityHint("One-time purchase that unlocks all Pro features")

                        Button {
                            Haptics.selection(enabled: settings.hapticsEnabled)
                            proStore.restore()
                            dismiss()
                        } label: {
                            Text("Restore purchase")
                                .font(Theme.rounded(16, .medium))
                                .foregroundStyle(Theme.accentDeep)
                        }

                        Text("One-time purchase. No subscription, no ads. Simulated checkout (StoreKit-ready).")
                            .font(.footnote)
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Caliper Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Maybe later") { dismiss() }
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.accent.opacity(0.15)).frame(width: 92, height: 92)
                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text("Go further with Pro")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
            Text("Unlock every site, advanced insights, unlimited goals and export. Your data stays private and on-device.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private func unlockRow(_ unlock: ProUnlock) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: unlock.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(unlock.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(unlock.detail)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(unlock.title). \(unlock.detail)")
    }
}
