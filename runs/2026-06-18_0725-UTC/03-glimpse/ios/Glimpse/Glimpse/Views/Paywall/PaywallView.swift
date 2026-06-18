import SwiftUI

/// Simulated one-time Pro unlock. StoreKit-ready; no real purchase here.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @State private var showRestoreNote = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    VStack(spacing: 12) {
                        ForEach(Pro.features) { feature in
                            featureRow(feature)
                        }
                    }
                    priceBlock
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Glimpse Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .alert("Nothing to restore", isPresented: $showRestoreNote) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("No previous purchase was found on this device. (Purchases are simulated in this build.)")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.heroGradient).frame(width: 92, height: 92)
                Image(systemName: "sparkles")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            Text(isPro ? "You have Glimpse Pro" : "Unlock the full ritual")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("A one-time unlock. Your core journal is always free.")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
    }

    private func featureRow(_ feature: Pro.Feature) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: feature.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(feature.detail)
                    .font(Theme.rounded(13, .regular))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }

    private var priceBlock: some View {
        VStack(spacing: 12) {
            if isPro {
                Label("Pro unlocked — thank you", systemImage: "checkmark.seal.fill")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.good)
                Button("Close") { dismiss() }
                    .font(Theme.rounded(15, .semibold))
                    .tint(Theme.accent)
            } else {
                Text(Pro.priceLabel)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                PrimaryButton(title: "Unlock Glimpse Pro", symbol: "lock.open.fill") {
                    Haptics.success(settings.hapticsEnabled)
                    isPro = true
                    dismiss()
                }
                Button("Restore purchase") {
                    showRestoreNote = true
                }
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.inkSoft)
                Button("Maybe later") { dismiss() }
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.inkSoft)
                Text("Simulated purchase — StoreKit-ready, no charge.")
                    .font(Theme.rounded(11, .regular))
                    .foregroundStyle(Theme.inkSoft.opacity(0.8))
            }
        }
        .padding(.top, 6)
    }
}
