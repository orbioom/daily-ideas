import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "character.book.closed.fill",
            title: "Learn Mandarin",
            body: "Master the 100 most essential HSK 1 characters — the foundation of Mandarin Chinese literacy.",
            accentColor: ShuTheme.gold
        ),
        OnboardingPage(
            icon: "brain.head.profile",
            title: "Spaced Repetition",
            body: "Shu uses the proven SM-2 algorithm to show you each character at exactly the right moment, so you remember forever.",
            accentColor: Color(red: 0.35, green: 0.70, blue: 0.96)
        ),
        OnboardingPage(
            icon: "speaker.wave.3.fill",
            title: "Hear It Spoken",
            body: "Every character is voiced by a native-quality Mandarin TTS engine. Tap any card to hear perfect pronunciation.",
            accentColor: ShuTheme.correctGreen
        ),
    ]

    var body: some View {
        ZStack {
            ShuTheme.darkNavy.ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { idx in
                        OnboardingPageView(page: pages[idx])
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { idx in
                        Capsule()
                            .fill(idx == currentPage ? ShuTheme.gold : ShuTheme.subtleText)
                            .frame(width: idx == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.35), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Action button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        isPresented = true
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Start Learning")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(ShuTheme.darkNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ShuTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: ShuTheme.buttonRadius))
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Supporting Types
private struct OnboardingPage {
    let icon: String
    let title: String
    let body: String
    let accentColor: Color
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon circle
            ZStack {
                Circle()
                    .fill(page.accentColor.opacity(0.15))
                    .frame(width: 140, height: 140)
                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(page.accentColor)
            }

            // Text
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(ShuTheme.primaryText)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(ShuTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    OnboardingView(isPresented: .constant(false))
}
