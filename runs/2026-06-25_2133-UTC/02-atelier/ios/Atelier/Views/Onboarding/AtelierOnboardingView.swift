import SwiftUI
import SwiftData

struct AtelierOnboardingView: View {
    @Query private var allSettings: [AtelierSettings]
    @Environment(\.modelContext) private var context
    @State private var page = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AtelierTheme.ink, AtelierTheme.charcoal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    OnboardPage(
                        sfSymbol: "paintpalette.fill",
                        title: "Your Art Studio",
                        body: "Track every practice session — medium, subject, skills worked, and how it felt. Build a record of your artistic journey.",
                        tag: 0
                    )
                    OnboardPage(
                        sfSymbol: "chart.bar.fill",
                        title: "See Your Growth",
                        body: "Watch your hours accumulate, skills progress from beginner to mastered, and streaks build over weeks and months.",
                        tag: 1
                    )
                    OnboardPage(
                        sfSymbol: "list.star",
                        title: "Master Your Skills",
                        body: "Curate a skills library across drawing, painting, perspective, anatomy, and more. Track status from learning to mastered.",
                        tag: 2
                    )
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == page ? AtelierTheme.amber : Color.white.opacity(0.3))
                            .frame(width: i == page ? 10 : 7, height: i == page ? 10 : 7)
                            .animation(.spring(response: 0.3), value: page)
                    }
                }
                .padding(.bottom, 24)

                Button(action: advance) {
                    Text(page == 2 ? "Start Practicing" : "Next")
                        .font(.headline)
                        .foregroundStyle(AtelierTheme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AtelierTheme.amber)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func advance() {
        if page < 2 { withAnimation { page += 1 } }
        else {
            allSettings.first?.showOnboarding = false
            try? context.save()
        }
    }
}

private struct OnboardPage: View {
    let sfSymbol: String
    let title: String
    let body: String
    let tag: Int

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: sfSymbol)
                .font(.system(size: 80, weight: .thin))
                .foregroundStyle(AtelierTheme.amber)
                .accessibilityHidden(true)
            VStack(spacing: 14) {
                Text(title)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text(body)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            Spacer()
        }
        .tag(tag)
        .padding(.horizontal, 24)
    }
}
