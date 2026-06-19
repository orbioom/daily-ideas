import SwiftUI

struct SparkOnboardingView: View {
    @AppStorage(SparkSettings.onboardingDone) private var onboardingDone = false
    @State private var page = 0

    private let pages: [(String, String, String)] = [
        ("bolt.fill", "One Task at a Time",
         "Spark shows you exactly one thing to focus on. No lists to scroll, no decisions to make. Just start."),
        ("timer", "Visual Focus Timer",
         "A large, calming countdown ring. See exactly how much time is left. Get a warning before each block ends."),
        ("chart.bar.fill", "Celebrate Your Focus",
         "Track focus streaks, daily minutes, and which tasks you crushed. ADHD-friendly progress that actually feels good."),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [SparkTheme.deepBlue, Color(red: 0.02, green: 0.08, blue: 0.20)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        VStack(spacing: 24) {
                            Image(systemName: pages[i].0)
                                .font(.system(size: 72))
                                .foregroundStyle(SparkTheme.electricBlue)
                                .accessibilityHidden(true)
                            Text(pages[i].1)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            Text(pages[i].2)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.80))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 380)

                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle()
                            .fill(i == page ? SparkTheme.electricBlue : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 20)
                Spacer()

                Button {
                    if page < pages.count - 1 { withAnimation { page += 1 } }
                    else { onboardingDone = true }
                } label: {
                    Text(page == pages.count - 1 ? "Let's Focus" : "Next")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(SparkTheme.electricBlue, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
