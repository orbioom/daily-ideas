import SwiftUI

struct PaywallView: View {
    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var toast: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.heroGradient.ignoresSafeArea()
                Starfield(count: 50).ignoresSafeArea().opacity(0.8)
                ScrollView {
                    VStack(spacing: 22) {
                        header
                        VStack(spacing: 12) {
                            ForEach(Pro.unlocks) { unlock in
                                unlockRow(unlock)
                            }
                        }
                        priceBlock
                        Text("Simulated purchase — StoreKit-ready. No real charge is made in this build.")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Maybe later") { dismiss() }
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .toast($toast)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(Theme.goldGradient)
                .accessibilityHidden(true)
            Text("Numen Pro")
                .font(Theme.serif(.largeTitle))
                .foregroundStyle(.white)
            Text("Unlock the complete experience, once and forever.")
                .font(Theme.serif(.body))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    private func unlockRow(_ unlock: ProUnlock) -> some View {
        HStack(spacing: 14) {
            Image(systemName: unlock.symbol)
                .font(.system(size: 20))
                .foregroundStyle(Theme.accent)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(unlock.title).font(Theme.rounded(15, .semibold)).foregroundStyle(.white)
                Text(unlock.detail).font(.footnote).foregroundStyle(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: Theme.cornerM))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(unlock.title). \(unlock.detail)")
    }

    private var priceBlock: some View {
        VStack(spacing: 12) {
            if isPro {
                Label("Numen Pro is active", systemImage: "checkmark.seal.fill")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.accent)
                Button("Done") { dismiss() }
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(.white)
            } else {
                Button {
                    purchase()
                } label: {
                    VStack(spacing: 2) {
                        Text("Unlock Numen Pro")
                            .font(Theme.rounded(17, .bold))
                        Text("\(Pro.price) · one-time")
                            .font(Theme.rounded(13, .medium))
                    }
                    .foregroundStyle(Color(hex: 0x140F22))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.goldGradient, in: Capsule())
                }
                Button("Restore Purchase") { restore() }
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private func purchase() {
        Haptics.success(enabled: settings.hapticsEnabled)
        withAnimation { isPro = true }
        toast = "Numen Pro unlocked"
    }

    private func restore() {
        if isPro {
            toast = "Pro already active"
        } else {
            // No prior purchase in this simulated build.
            toast = "No purchase found to restore"
            Haptics.warning(enabled: settings.hapticsEnabled)
        }
    }
}
