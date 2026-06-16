import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings
    @State private var showThanks = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    hero
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
            .navigationTitle("Pip Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Maybe later") { dismiss() }
                }
            }
            .overlay {
                if showThanks {
                    ToastView(text: "Welcome to Pip Pro!", icon: "checkmark.seal.fill")
                }
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.accentSoft).frame(width: 92, height: 92)
                Image(systemName: "die.face.6.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text("Unlock the full table")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("One payment. No ads, ever. No subscriptions.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func featureRow(_ feature: Pro.Feature) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Theme.accentSoft)
                    .frame(width: 44, height: 44)
                Image(systemName: feature.icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title).font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                Text(feature.detail).font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .accessibilityElement(children: .combine)
    }

    private var priceBlock: some View {
        VStack(spacing: 12) {
            if isPro {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Pip Pro is unlocked").font(Theme.rounded(17, .bold))
                }
                .foregroundStyle(Theme.accent)
            } else {
                PrimaryButton(title: "Unlock Pip Pro · \(Pro.price)", icon: "lock.open.fill") {
                    unlock()
                }
                Button("Restore purchase") {
                    // Simulated; no prior purchase in this build.
                }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
                Text("Simulated purchase — StoreKit-ready. \(Pro.price) one-time, no subscription.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 4)
    }

    private func unlock() {
        Haptics.win(enabled: settings.hapticsEnabled)
        withAnimation { isPro = true; showThanks = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            dismiss()
        }
    }
}
