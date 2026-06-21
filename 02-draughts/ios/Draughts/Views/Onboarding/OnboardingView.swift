import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Query private var onboardingList: [DraughtsOnboarding]
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "checkerboard.rectangle",
            title: "Checkers, Perfected",
            body: "Draughts brings the timeless game of Checkers to your iPhone. No ads. No subscriptions. Just pure, polished gameplay.",
            accent: DraughtsTheme.gold
        ),
        OnboardingPage(
            icon: "crown.fill",
            title: "Know the Rules",
            body: "Move pieces diagonally on dark squares. Jump over opponents to capture them. If a jump is available, you must take it. Reach the back row to become a King.",
            accent: DraughtsTheme.redPiece
        ),
        OnboardingPage(
            icon: "gamecontroller.fill",
            title: "You're Ready",
            body: "Challenge the AI at three difficulty levels — Easy, Medium, and Hard. Tap a piece to see your moves, then tap a destination to play.",
            accent: Color(red: 0.30, green: 0.75, blue: 0.40)
        )
    ]

    var body: some View {
        ZStack {
            DraughtsTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { idx in
                        pageView(pages[idx])
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: currentPage)

                // Page dots + CTA
                VStack(spacing: 24) {
                    pageDots

                    if currentPage < pages.count - 1 {
                        HStack {
                            Button("Skip") { completeOnboarding() }
                                .font(.subheadline)
                                .foregroundStyle(DraughtsTheme.text.opacity(0.50))

                            Spacer()

                            Button {
                                withAnimation { currentPage += 1 }
                            } label: {
                                Label("Next", systemImage: "arrow.right")
                                    .font(.headline)
                                    .foregroundStyle(DraughtsTheme.background)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 14)
                                    .background(DraughtsTheme.gold)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 32)
                    } else {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Let's Play!")
                                .font(.headline)
                                .foregroundStyle(DraughtsTheme.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(DraughtsTheme.gold)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Page View

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.accent.opacity(0.15))
                    .frame(width: 160, height: 160)

                Image(systemName: page.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .foregroundStyle(page.accent)
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(DraughtsTheme.text)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.body)
                    .foregroundStyle(DraughtsTheme.text.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Page Dots

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { idx in
                Capsule()
                    .fill(idx == currentPage ? DraughtsTheme.gold : DraughtsTheme.text.opacity(0.25))
                    .frame(width: idx == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
    }

    // MARK: - Complete

    private func completeOnboarding() {
        let record: DraughtsOnboarding
        if let existing = onboardingList.first {
            record = existing
        } else {
            record = DraughtsOnboarding()
            modelContext.insert(record)
        }
        record.hasCompletedOnboarding = true
        try? modelContext.save()
    }
}

// MARK: - Model

private struct OnboardingPage {
    let icon: String
    let title: String
    let body: String
    let accent: Color
}

#Preview {
    OnboardingView()
        .modelContainer(for: [DraughtsOnboarding.self], inMemory: true)
}
