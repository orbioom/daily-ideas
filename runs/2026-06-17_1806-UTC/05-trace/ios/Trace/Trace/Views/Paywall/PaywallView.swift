import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Environment(\.dismiss) private var dismiss

    @State private var showRestoreNote = false

    var body: some View {
        NavigationStack {
            ZStack {
                WarmBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        hero
                        benefitsList
                        priceAndBuy
                        footer
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Trace Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Maybe later") { dismiss() }
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .alert("Restore", isPresented: $showRestoreNote) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(isPro ? "Trace Pro is active. Thank you!" : "No previous purchase was found on this device.")
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(Theme.heroGradient).frame(width: 110, height: 110)
                Image(systemName: "sparkles")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            Text("Unlock everything")
                .font(Theme.rounded(28, .heavy))
                .foregroundStyle(Theme.ink)
            Text("One purchase. The whole learning playground.")
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var benefitsList: some View {
        VStack(spacing: 14) {
            ForEach(Pro.benefits) { benefit in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: benefit.icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 34)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(benefit.title)
                            .font(Theme.rounded(18, .bold))
                            .foregroundStyle(Theme.ink)
                        Text(benefit.detail)
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(18)
        .card()
    }

    private var priceAndBuy: some View {
        VStack(spacing: 12) {
            if isPro {
                Label("You have Trace Pro", systemImage: "checkmark.seal.fill")
                    .font(Theme.rounded(20, .bold))
                    .foregroundStyle(Theme.good)
                ChunkyButton(title: "Done", systemImage: "checkmark") { dismiss() }
            } else {
                Text("\(Pro.priceDisplay) · one-time")
                    .font(Theme.rounded(22, .heavy))
                    .foregroundStyle(Theme.ink)
                ChunkyButton(title: "Unlock Trace Pro", systemImage: "lock.open.fill") {
                    unlock()
                }
                Button("Restore purchase") { showRestoreNote = true }
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.accentDeep)
            }
        }
    }

    private var footer: some View {
        Text("No ads. No subscriptions. No data collection. Simulated purchase for this build (StoreKit-ready).")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkSoft)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }

    private func unlock() {
        isPro = true
        Haptics.success(enabled: settings.hapticsEnabled)
        SoundPlayer.success(enabled: settings.soundEnabled)
        dismiss()
    }
}
