import SwiftUI

struct OnboardingView: View {
    @Query private var settings: [CrescentSettings]
    @Environment(\.modelContext) private var context
    @State private var page = 0

    var body: some View {
        ZStack {
            CrescentTheme.navy.ignoresSafeArea()
            TabView(selection: $page) {
                OnboardPage(
                    symbol: "🌑",
                    title: "Welcome to Crescent",
                    body: "Your private lunar companion — track the moon's phases, write intention journals, and discover your cosmic rhythm.",
                    isLast: false, onNext: { page = 1 }
                ).tag(0)

                OnboardPage(
                    symbol: "🌕",
                    title: "Lunar Living",
                    body: "Each moon phase carries unique energy. New moons invite beginnings; full moons bring release. Align your life with these natural rhythms.",
                    isLast: false, onNext: { page = 2 }
                ).tag(1)

                OnboardPage(
                    symbol: "📓",
                    title: "Journal & Rituals",
                    body: "Write moon-phase-aware journal entries, follow guided rituals, and discover how the moon influences your mood and energy.",
                    isLast: true, onNext: { finish() }
                ).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut, value: page)
        }
    }

    private func finish() {
        if let s = settings.first { s.hasCompletedOnboarding = true }
    }
}

private struct OnboardPage: View {
    let symbol: String
    let title: String
    let body: String
    let isLast: Bool
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text(symbol).font(.system(size: 100))
            Text(title)
                .font(.system(size: 28, weight: .light, design: .serif))
                .foregroundColor(CrescentTheme.pearl)
                .multilineTextAlignment(.center)
            Text(body)
                .font(.body)
                .foregroundColor(CrescentTheme.silver)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
            Button(action: onNext) {
                Text(isLast ? "Begin My Journey" : "Continue")
                    .font(.headline)
                    .foregroundColor(CrescentTheme.navy)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(CrescentTheme.gold)
                    .cornerRadius(14)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 50)
        }
    }
}
