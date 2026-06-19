import SwiftUI

struct MistOnboardingView: View {
    @AppStorage("mistHasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0

    private let pages: [(title: String, body: String, symbol: String)] = [
        ("Track Every Session", "Log your sauna, cold plunge, steam room, and contrast therapy sessions all in one place.", "thermometer.medium"),
        ("Follow Expert Protocols", "Built-in protocols from Finnish tradition, Huberman Lab, and Wim Hof to guide your practice.", "list.bullet.clipboard.fill"),
        ("See Your Progress", "Track streaks, total time, personal records, and session history over time.", "chart.line.uptrend.xyaxis")
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.05, green: 0.18, blue: 0.22), Color(red: 0.02, green: 0.10, blue: 0.14)],
                          startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        VStack(spacing: 32) {
                            Spacer()
                            Image(systemName: pages[i].symbol)
                                .font(.system(size: 80))
                                .foregroundStyle(Color(red: 0.2, green: 0.85, blue: 0.85))
                                .symbolEffect(.pulse)

                            VStack(spacing: 12) {
                                Text(pages[i].title)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                Text(pages[i].body)
                                    .font(.system(size: 17, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            Spacer()
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 460)

                Button(action: {
                    if page < pages.count - 1 { withAnimation { page += 1 } }
                    else { hasSeenOnboarding = true }
                }) {
                    Text(page < pages.count - 1 ? "Next" : "Get Started")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.15, green: 0.7, blue: 0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
