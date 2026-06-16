import SwiftUI

/// A tasteful, kind paywall. Simulated one-time unlock via @AppStorage("isPro").
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage(PrefKey.isPro) private var isPro = false
    @State private var unlocking = false
    @State private var justUnlocked = false

    private let perks: [(String, String)] = [
        ("wind", "Every breathing pattern — Box, 4-7-8, Calm and Coherent"),
        ("chart.xyaxis.line", "Full insights: relief, triggers, time-of-day & what helps"),
        ("infinity", "Unlimited custom coping tools, cards and triggers"),
        ("bell.badge", "Gentle, optional daily check-ins")
    ]

    var body: some View {
        ZStack {
            HavenBackground()
            ScrollView {
                VStack(spacing: 22) {
                    header
                    perksCard
                    if justUnlocked || isPro {
                        unlockedState
                    } else {
                        purchase
                    }
                    fairnessNote
                }
                .padding(24)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(HavenTheme.secondaryText(scheme))
                }
                .accessibilityLabel("Close")
            }
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(HavenTheme.accent)
                .accessibilityHidden(true)
            Text("Haven Plus")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(HavenTheme.primaryText(scheme))
            Text("One quiet payment. Yours for good. No subscription.")
                .font(.subheadline)
                .foregroundStyle(HavenTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
        }
    }

    private var perksCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(perks, id: \.0) { perk in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: perk.0)
                            .foregroundStyle(HavenTheme.accent)
                            .frame(width: 26)
                            .accessibilityHidden(true)
                        Text(perk.1)
                            .font(.subheadline)
                            .foregroundStyle(HavenTheme.primaryText(scheme))
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var purchase: some View {
        VStack(spacing: 12) {
            Button {
                simulateUnlock()
            } label: {
                if unlocking {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(HavenTheme.sosGradient)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerLarge, style: .continuous))
                } else {
                    Text("Unlock for $4.99")
                        .havenPillButtonLabel()
                }
            }
            .disabled(unlocking)
            .accessibilityLabel("Unlock Haven Plus for 4 dollars 99 cents, one time")

            Text("Simulated purchase for this demo build.")
                .font(.caption2)
                .foregroundStyle(HavenTheme.secondaryText(scheme))
        }
    }

    private var unlockedState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(HavenTheme.calmGreen.opacity(0.15)).frame(width: 96, height: 96)
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(HavenTheme.calmGreen)
            }
            .accessibilityHidden(true)
            Text("You're all set")
                .font(.title2.weight(.bold))
                .foregroundStyle(HavenTheme.primaryText(scheme))
            Text("Thank you. Everything in Haven is now open to you.")
                .font(.subheadline)
                .foregroundStyle(HavenTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
            Button("Done") { dismiss() }
                .havenPillButton()
        }
        .accessibilityElement(children: .combine)
    }

    private var fairnessNote: some View {
        Text("Most calming apps charge every month. We think a tool for your hard moments shouldn't feel like a meter running. Pay once, keep it forever.")
            .font(.footnote)
            .foregroundStyle(HavenTheme.secondaryText(scheme))
            .multilineTextAlignment(.center)
    }

    private func simulateUnlock() {
        unlocking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            unlocking = false
            if reduceMotion {
                isPro = true
                justUnlocked = true
            } else {
                withAnimation(.easeInOut) {
                    isPro = true
                    justUnlocked = true
                }
            }
        }
    }
}

private extension View {
    func havenPillButtonLabel() -> some View {
        self
            .font(.headline)
            .foregroundStyle(Color.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(HavenTheme.sosGradient)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerLarge, style: .continuous))
    }
}
