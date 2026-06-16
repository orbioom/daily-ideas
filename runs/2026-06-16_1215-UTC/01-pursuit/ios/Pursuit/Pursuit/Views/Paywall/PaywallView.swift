import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore

    /// Optional context-specific reason shown at the top.
    var reason: String? = nil

    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    if let reason {
                        Text(reason)
                            .font(Theme.rounded(14, .medium))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    benefits
                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .padding(20)
                .padding(.bottom, 140)
            }
            .background(Theme.bg.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) { purchaseBar }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.inkFaint) }
                        .accessibilityLabel("Close")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.accent.opacity(0.14)).frame(width: 90, height: 90)
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            Text(ProStore.productName)
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
            Text("One-time unlock. No subscription. Yours forever.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var benefits: some View {
        VStack(spacing: 12) {
            ForEach(ProBenefit.all) { benefit in
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.accent.opacity(0.14))
                            .frame(width: 40, height: 40)
                        Image(systemName: benefit.symbol)
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(benefit.title)
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text(benefit.detail)
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
    }

    private var purchaseBar: some View {
        VStack(spacing: 10) {
            Button {
                pro.unlock()
                Haptics.notify(.success, enabled: settings.hapticsEnabled)
                dismiss()
            } label: {
                HStack {
                    Text("Unlock for")
                    Text(ProStore.priceText).fontWeight(.heavy)
                }
                .font(Theme.rounded(17, .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous))
                .foregroundStyle(.white)
            }
            .accessibilityHint("Unlocks all Pursuit Pro features")

            HStack(spacing: 18) {
                Button("Restore") {
                    let restored = pro.restore()
                    restoreMessage = restored ? "Pro restored." : "No previous purchase found."
                    if restored { Haptics.notify(.success, enabled: settings.hapticsEnabled); dismiss() }
                }
                Button("Maybe later") { dismiss() }
            }
            .font(Theme.rounded(14, .medium))
            .foregroundStyle(Theme.inkSoft)

            Text("Simulated purchase — StoreKit-ready. Nothing is charged.")
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .top)
    }
}
