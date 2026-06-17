import SwiftUI

struct PaywallView: View {
    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var toast: ToastMessage?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 22) {
                        hero
                        unlocks
                        purchase
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Thump Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Maybe later") { dismiss() }
                        .font(Theme.rounded(15))
                }
            }
            .toast($toast)
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.heroGradient).frame(width: 92, height: 92)
                    .shadow(color: Theme.accent.opacity(0.5), radius: 20, y: 8)
                Image(systemName: "crown.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            Text("Unlock the full rack")
                .font(Theme.rounded(24, .heavy))
                .foregroundStyle(Theme.ink)
            Text("A one-time unlock. No subscriptions, no ads — ever.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var unlocks: some View {
        PanelCard {
            VStack(spacing: 16) {
                ForEach(Array(Pro.unlocks.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 30)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(Theme.rounded(16, .bold))
                                .foregroundStyle(Theme.ink)
                            Text(item.detail)
                                .font(Theme.rounded(13))
                                .foregroundStyle(Theme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("\(item.title). \(item.detail)"))
                }
            }
        }
    }

    private var purchase: some View {
        VStack(spacing: 10) {
            if isPro {
                HStack {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.good)
                    Text("Pro is active — thank you!")
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.vertical, 8)
                PrimaryButton(title: "Done", fill: false) { dismiss() }
            } else {
                PrimaryButton(title: "Unlock Thump Pro · \(Pro.priceLabel)", symbol: "crown.fill") {
                    unlock()
                }
                Button("Restore Purchases") { restore() }
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                Text("Simulated purchase — StoreKit-ready, no real charge.")
                    .font(Theme.rounded(11))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func unlock() {
        Haptics.success(settings.hapticsEnabled)
        isPro = true
        toast = ToastMessage(text: "Thump Pro unlocked!", symbol: "crown.fill")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { dismiss() }
    }

    private func restore() {
        if isPro {
            toast = ToastMessage(text: "Pro already active", symbol: "checkmark.circle.fill")
        } else {
            toast = ToastMessage(text: "No previous purchase found", symbol: "info.circle.fill")
        }
        Haptics.tap(settings.hapticsEnabled)
    }
}
