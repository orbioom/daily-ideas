import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var proStore: ProStore

    @State private var showRestoreNote = false
    @State private var restoreText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    featureList
                    priceBlock
                    legalNote
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Lane Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Restore", isPresented: $showRestoreNote) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(restoreText)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Theme.heroGradient)
                    .frame(width: 96, height: 96)
                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            Text("Unlock everything in Lane")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("One payment. Yours forever. No subscription.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var featureList: some View {
        VStack(spacing: 0) {
            ForEach(Array(ProFeature.allCases.enumerated()), id: \.element.id) { idx, feature in
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle().fill(Theme.accentSoft).frame(width: 40, height: 40)
                        Image(systemName: feature.symbol)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(feature.title)
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text(feature.detail)
                            .font(.caption)
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 12)
                .accessibilityElement(children: .combine)

                if idx < ProFeature.allCases.count - 1 {
                    Divider().background(Theme.hairline)
                }
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    private var priceBlock: some View {
        VStack(spacing: 12) {
            if proStore.isPro {
                SwiftUI.Label("You already own Lane Pro", systemImage: "checkmark.seal.fill")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.good)
            } else {
                Button {
                    unlock()
                } label: {
                    VStack(spacing: 2) {
                        Text("Unlock Lane Pro")
                            .font(Theme.rounded(17, .bold))
                        Text("\(ProStore.priceLabel) · one-time")
                            .font(.caption)
                            .opacity(0.9)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.white)
                }
                .accessibilityHint("Unlocks all Pro features")

                Button("Restore Purchase") { restore() }
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.accent)

                Button("Maybe later") { dismiss() }
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private var legalNote: some View {
        Text("Simulated purchase for this build. The unlock is stored on-device and is StoreKit-ready for App Store distribution.")
            .font(.caption2)
            .foregroundStyle(Theme.inkSoft)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }

    private func unlock() {
        proStore.unlock()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func restore() {
        let restored = proStore.restore()
        restoreText = restored ? "Lane Pro has been restored." : "No previous purchase was found on this device."
        showRestoreNote = true
        if restored { dismiss() }
    }
}
