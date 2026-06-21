import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Query private var onboardingList: [AtomOnboarding]
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var onboarding: AtomOnboarding {
        if let o = onboardingList.first { return o }
        let o = AtomOnboarding(); modelContext.insert(o); return o
    }

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "atom",
            title: "118 Elements",
            subtitle: "at your fingertips",
            description: "The complete periodic table with scientific data, history, and fun facts for every element from Hydrogen to Oganesson.",
            accentColor: Color(red: 0.30, green: 0.60, blue: 1.00)
        ),
        OnboardingPage(
            icon: "tablecells",
            title: "Interactive Table",
            subtitle: "pinch to explore",
            description: "Zoom and pan across a full periodic table. Color-coded by category. Tap any element for deep details.",
            accentColor: Color(red: 0.55, green: 0.75, blue: 0.95)
        ),
        OnboardingPage(
            icon: "brain.head.profile",
            title: "Smart Quizzes",
            subtitle: "test your knowledge",
            description: "Four quiz modes, adaptive difficulty, streaks, and detailed stats. Master chemistry one element at a time.",
            accentColor: Color(red: 0.65, green: 0.35, blue: 0.90)
        )
    ]

    var body: some View {
        ZStack {
            AtomTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                        OnboardingPageView(page: page)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: currentPage)

                // Dots + buttons
                VStack(spacing: 28) {
                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { idx in
                            Circle()
                                .fill(idx == currentPage ? AtomTheme.accent : AtomTheme.textTertiary)
                                .frame(width: idx == currentPage ? 10 : 6, height: idx == currentPage ? 10 : 6)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    // Action button
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Next" : "Start Exploring")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AtomButtonStyle())
                    .padding(.horizontal, 32)

                    if currentPage < pages.count - 1 {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundStyle(AtomTheme.textTertiary)
                        }
                    } else {
                        Spacer().frame(height: 20)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func completeOnboarding() {
        onboarding.completed = true
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let accentColor: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.accentColor.opacity(0.15))
                    .frame(width: 140, height: 140)
                Image(systemName: page.icon)
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(page.accentColor)
            }

            // Text
            VStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text(page.title)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(AtomTheme.textPrimary)
                    Text(page.subtitle)
                        .font(.title3)
                        .foregroundStyle(page.accentColor)
                }

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(AtomTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [AtomOnboarding.self])
        .preferredColorScheme(.dark)
}
