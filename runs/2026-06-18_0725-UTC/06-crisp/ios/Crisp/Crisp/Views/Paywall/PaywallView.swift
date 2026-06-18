import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var unlocked = false

    private struct Perk: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    private let perks: [Perk] = [
        Perk(icon: "timer", title: "Unlimited timers",
             detail: "Run every basket at once — past the free \(ProLimits.freeTimerCap)-timer cap."),
        Perk(icon: "square.stack.3d.up", title: "Unlimited custom foods",
             detail: "Save all your own recipes, not just \(ProLimits.freeCustomFoodCap)."),
        Perk(icon: "thermometer.medium", title: "Full doneness guide",
             detail: "Every chef-preferred internal temp, not only the core set."),
        Perk(icon: "nosign", title: "No nags, ever",
             detail: "A clean, calm cooking app — no ads, no interruptions."),
        Perk(icon: "heart.fill", title: "Support an indie maker",
             detail: "One-time unlock. No subscription, yours forever."),
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    header
                    VStack(spacing: 12) {
                        ForEach(perks) { perk in
                            perkRow(perk)
                        }
                    }
                    buttons
                }
                .padding(20)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.inkSoft)
                    .padding(16)
            }
            .accessibilityLabel("Close")
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.surfaceAlt).frame(width: 92, height: 92)
                Image(systemName: "flame.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Theme.accent)
                    .scaleEffect(unlocked && !reduceMotion ? 1.15 : 1)
                    .accessibilityHidden(true)
            }
            .padding(.top, 12)
            Text("Crisp Pro")
                .font(Theme.roundedStyle(.largeTitle, .bold))
                .foregroundStyle(Theme.ink)
            Text("Everything unlocked, one time.")
                .font(Theme.roundedStyle(.subheadline))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private func perkRow(_ perk: Perk) -> some View {
        HStack(spacing: 14) {
            Image(systemName: perk.icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(perk.title)
                    .font(Theme.roundedStyle(.headline, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(perk.detail)
                    .font(Theme.roundedStyle(.footnote))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .crispCard()
        .accessibilityElement(children: .combine)
    }

    private var buttons: some View {
        VStack(spacing: 10) {
            if pro.isPro {
                Label("You're all set — Pro is active", systemImage: "checkmark.seal.fill")
                    .font(Theme.roundedStyle(.headline, .bold))
                    .foregroundStyle(Theme.good)
                    .padding(.vertical, 8)
            } else {
                Text("$4.99 · one-time")
                    .font(Theme.roundedStyle(.subheadline, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                PrimaryButton(title: "Unlock Crisp Pro", systemImage: "lock.open.fill") {
                    unlock()
                }
                Button("Restore purchase") {
                    pro.restore()
                }
                .font(Theme.roundedStyle(.subheadline, .semibold))
                .foregroundStyle(Theme.accent)
                Button("Maybe later") { dismiss() }
                    .font(Theme.roundedStyle(.subheadline))
                    .foregroundStyle(Theme.inkSoft)
            }
            Text("Simulated purchase — StoreKit-ready for the App Store build.")
                .font(Theme.roundedStyle(.caption2))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }

    private func unlock() {
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        withAnimation(reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.6)) {
            unlocked = true
            pro.unlock()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            dismiss()
        }
    }
}
