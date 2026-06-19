import SwiftUI

struct CastOnboardingView: View {
    @AppStorage(CastSettings.onboardingDone) private var onboardingDone = false
    @State private var page = 0

    private let pages: [(String, String, String)] = [
        ("mic.fill", "Track Every Listen", "Add your favorite shows and mark episodes as you listen. Your personal podcast diary."),
        ("list.bullet", "Build Your Queue", "Curate episodes you want to hear next. Never forget a great recommendation."),
        ("chart.bar.fill", "See Your Listening Stats", "Hours logged, genres explored, listening streaks — all the numbers that matter to you."),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [CastTheme.purple, Color(red: 0.20, green: 0.08, blue: 0.45)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        VStack(spacing: 24) {
                            Image(systemName: pages[i].0)
                                .font(.system(size: 72))
                                .foregroundStyle(.white)
                                .accessibilityHidden(true)
                            Text(pages[i].1)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            Text(pages[i].2)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 360)

                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle()
                            .fill(i == page ? Color.white : Color.white.opacity(0.4))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 20)
                Spacer()

                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        onboardingDone = true
                    }
                } label: {
                    Text(page == pages.count - 1 ? "Start Tracking" : "Next")
                        .font(.headline)
                        .foregroundStyle(CastTheme.purple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
