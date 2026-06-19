import SwiftUI
import SwiftData

struct MemoirOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0

    var onFinish: () -> Void

    var body: some View {
        ZStack {
            MemoirTheme.parchment.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        systemImage: "book.closed.fill",
                        imageColor: MemoirTheme.warmAmber,
                        headline: "Your Story Matters",
                        body: "Every life holds extraordinary moments. Capture your memories before they fade — the small details, the turning points, the people who shaped you.",
                        tag: 0
                    )

                    OnboardingPage(
                        systemImage: "text.bubble.fill",
                        imageColor: MemoirTheme.forestGreen,
                        headline: "Writing Prompts",
                        body: "Guided questions unlock stories you forgot you had. Each week, a new prompt gently leads you back to a memory worth preserving.",
                        tag: 1
                    )

                    OnboardingPage(
                        systemImage: "person.2.fill",
                        imageColor: MemoirTheme.inkBrown,
                        headline: "Build Your Legacy",
                        body: "Create a private, beautiful record of your life — chapter by chapter. Your story, entirely offline and entirely yours.",
                        tag: 2
                    )
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicator dots
                HStack(spacing: 10) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index == currentPage ? MemoirTheme.warmAmber : MemoirTheme.inkBrown.opacity(0.25))
                            .frame(width: index == currentPage ? 10 : 7, height: index == currentPage ? 10 : 7)
                            .animation(.spring(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 8)

                // Buttons
                VStack(spacing: 12) {
                    if currentPage < 2 {
                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            Text("Continue")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(MemoirTheme.warmAmber)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    } else {
                        Button {
                            seedPromptsAndFinish()
                        } label: {
                            Text("Start Writing My Story")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(MemoirTheme.warmAmber)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    if currentPage < 2 {
                        Button {
                            seedPromptsAndFinish()
                        } label: {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundColor(MemoirTheme.inkBrown.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func seedPromptsAndFinish() {
        let prompts = WritingPrompt.defaultPrompts
        for prompt in prompts {
            modelContext.insert(prompt)
        }
        try? modelContext.save()
        MemoirSettings.onboardingDone = true
        onFinish()
    }
}

// MARK: - OnboardingPage

private struct OnboardingPage: View {
    let systemImage: String
    let imageColor: Color
    let headline: String
    let body: String
    let tag: Int

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(imageColor.opacity(0.15))
                    .frame(width: 140, height: 140)
                Image(systemName: systemImage)
                    .font(.system(size: 60))
                    .foregroundColor(imageColor)
            }

            VStack(spacing: 16) {
                Text(headline)
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundColor(MemoirTheme.inkBrown)
                    .multilineTextAlignment(.center)

                Text(body)
                    .font(.system(.body, design: .serif))
                    .foregroundColor(MemoirTheme.inkBrown.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
        .tag(tag)
    }
}
