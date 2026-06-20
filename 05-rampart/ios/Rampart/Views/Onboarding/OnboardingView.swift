import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [RampartSettings]
    @State private var page = 0

    private var settings: RampartSettings? { settingsQuery.first }

    private let pages: [(icon: String, title: String, body: String)] = [
        (
            "🏰",
            "Welcome to Rampart",
            "Enemy hordes march toward your gate. Place towers to stop them before they breach the walls. Strategy wins — brute force fails."
        ),
        (
            "🗼",
            "Three Tower Types",
            "🏹 Archer — Fast and cheap\n💣 Cannon — Slow, heavy splash damage\n❄️ Frost — Slows enemies for your cannons\n\nCombine them to counter every wave."
        ),
        (
            "🐉",
            "Five Maps, Five Foes",
            "Take on Goblins, Orcs, Trolls, and Dragons across five maps of increasing brutality. Each wave grows stronger. Spend your gold wisely."
        )
    ]

    var body: some View {
        ZStack {
            RampartTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { i, p in
                        VStack(spacing: RampartTheme.spacingL) {
                            Spacer()
                            Text(p.icon)
                                .font(.system(size: 80))
                            Text(p.title)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(RampartTheme.gold)
                                .multilineTextAlignment(.center)
                            Text(p.body)
                                .font(RampartTheme.bodyFont)
                                .foregroundStyle(RampartTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(5)
                                .padding(.horizontal, RampartTheme.spacingXL)
                            Spacer()
                            Spacer()
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? RampartTheme.gold : RampartTheme.textTertiary)
                            .frame(width: i == page ? 20 : 7, height: 7)
                            .animation(.spring(response: 0.3), value: page)
                    }
                }
                .padding(.vertical, 16)

                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Next" : "Defend!")
                        .font(RampartTheme.headlineFont)
                        .foregroundStyle(RampartTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RampartTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: RampartTheme.radiusL))
                }
                .padding(.horizontal, RampartTheme.spacingL)
                .padding(.bottom, 50)
            }
        }
    }

    private func completeOnboarding() {
        if let s = settings {
            s.hasCompletedOnboarding = true
        } else {
            let s = RampartSettings()
            s.hasCompletedOnboarding = true
            modelContext.insert(s)
        }
        try? modelContext.save()
    }
}
