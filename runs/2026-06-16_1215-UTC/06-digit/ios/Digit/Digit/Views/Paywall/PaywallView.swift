import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showRestoreToast = false
    @State private var showUnlockedToast = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    perksList
                    priceSection
                    legal
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.inkSoft.opacity(0.6))
                    }
                    .accessibilityLabel("Close")
                }
            }
            .toast(isPresented: $showRestoreToast, symbol: "checkmark.seal.fill",
                   message: settings.isPro ? "Purchase restored!" : "Nothing to restore yet")
            .toast(isPresented: $showUnlockedToast, symbol: "sparkles", message: "Digit Pro unlocked!")
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.heroGradient).frame(width: 90, height: 90)
                Image(systemName: "infinity")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
            Text(Pro.productName)
                .font(Theme.rounded(30, .bold))
                .foregroundStyle(Theme.ink)
            Text("Everything Digit can do — one simple, one-time purchase.")
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    private var perksList: some View {
        VStack(spacing: 12) {
            ForEach(Pro.perks) { perk in
                Card(padding: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: perk.symbol)
                            .font(Theme.rounded(20, .bold))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(perk.title)
                                .font(Theme.rounded(16, .bold))
                                .foregroundStyle(Theme.ink)
                            Text(perk.detail)
                                .font(Theme.rounded(13))
                                .foregroundStyle(Theme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var priceSection: some View {
        if settings.isPro {
            Card {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.good)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You have Digit Pro")
                            .font(Theme.rounded(18, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("Thank you for supporting Digit!")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                }
            }
        } else {
            VStack(spacing: 12) {
                Text("\(Pro.priceLabel) once · no subscription")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                PrimaryButton(title: "Unlock \(Pro.productName)", systemImage: "sparkles") {
                    unlock()
                }
                Button("Restore purchase") { restore() }
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.accent)
                Button("Maybe later") { dismiss() }
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private var legal: some View {
        Text("Simulated purchase for this build (StoreKit-ready). No real charge is made.")
            .font(Theme.rounded(11))
            .foregroundStyle(Theme.inkSoft.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }

    private func unlock() {
        settings.isPro = true
        Haptics.success(settings.hapticsEnabled)
        showUnlockedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
    }

    private func restore() {
        Haptics.tap(settings.hapticsEnabled)
        showRestoreToast = true
    }
}
