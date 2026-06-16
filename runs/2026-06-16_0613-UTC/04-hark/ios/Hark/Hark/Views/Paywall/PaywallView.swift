import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Environment(\.dismiss) private var dismiss

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

                    Text("One-time purchase. Simulated for this build — StoreKit-ready, no real charge.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Hark Pro")
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
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.accentSoft).frame(width: 96, height: 96)
                Image(systemName: "ear.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text("Go deeper with Hark Pro")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("Your screening is free forever. Pro adds history, trends, tools, and export — paid once, kept private.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func featureRow(_ feature: Pro.Feature) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.accentSoft)
                    .frame(width: 44, height: 44)
                Image(systemName: feature.icon)
                    .font(Theme.rounded(18, .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(feature.detail)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: Theme.rCard, style: .continuous).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: Theme.rCard, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private var priceBlock: some View {
        VStack(spacing: 12) {
            if isPro {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.good)
                    Text("You have Hark Pro")
                        .font(Theme.rounded(17, .semibold))
                        .foregroundStyle(Theme.ink)
                }
                .accessibilityElement(children: .combine)
            } else {
                Button {
                    Haptics.success(enabled: settings.hapticsEnabled)
                    isPro = true
                    dismiss()
                } label: {
                    PrimaryButtonLabel(title: "Unlock \(Pro.productName) — \(Pro.priceLabel)")
                }
                .buttonStyle(.plain)
                .accessibilityHint("Unlocks all Pro features.")

                Button("Maybe later") { dismiss() }
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }
}
