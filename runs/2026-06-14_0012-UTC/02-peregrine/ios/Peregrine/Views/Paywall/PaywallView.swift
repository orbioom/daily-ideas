import SwiftUI

/// Honest one-time-unlock paywall. Backed by `@AppStorage("isPro")` for this
/// build; production would wire StoreKit 2.
struct PaywallView: View {
    @AppStorage("isPro") private var isPro = false
    @Environment(\.dismiss) private var dismiss

    private struct Perk: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    private let perks: [Perk] = [
        Perk(icon: "globe", title: "Every continent", detail: "Unlock all six continents, not just three."),
        Perk(icon: "square.grid.2x2.fill", title: "All quiz modes", detail: "Capital→Country, Flag→Continent and Population mode."),
        Perk(icon: "infinity", title: "Unlimited quizzes", detail: "No daily cap — practice as much as you like."),
        Perk(icon: "chart.bar.fill", title: "Full statistics", detail: "Deep progress, trends and every achievement.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    VStack(spacing: 14) {
                        ForEach(perks) { perk in
                            perkRow(perk)
                        }
                    }
                    buttons
                    footnote
                }
                .padding(24)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Peregrine Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.accentSoft).frame(width: 96, height: 96)
                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text("Explore the whole world")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("A single one-time unlock — no subscription.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private func perkRow(_ perk: Perk) -> some View {
        HStack(spacing: 14) {
            Image(systemName: perk.icon)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(perk.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(perk.detail)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            if isPro {
                Label("Pro is active", systemImage: "checkmark.seal.fill")
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.good)
                    .padding(.vertical, 8)
            } else {
                PrimaryButton(title: "Unlock Peregrine Pro · $4.99", systemImage: "lock.open.fill") {
                    Haptics.celebrate()
                    isPro = true
                }
                Button("Restore purchase") {
                    // No StoreKit in this build; restore is a no-op that simply
                    // re-affirms local state without dark patterns.
                    Haptics.tap()
                }
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.accent)
            }
        }
        .padding(.top, 4)
    }

    private var footnote: some View {
        Text("Demo build: unlocks locally on this device. Production wires StoreKit 2 for the one-time purchase and restore.")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }
}

#Preview {
    PaywallView()
}
