import SwiftUI

struct OnboardingView: View {
    @AppStorage(TrekSettings.onboardingCompleted) private var onboardingDone = false
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("mountain.2.fill", "Your Personal Trail Log",
         "Record every hike — distance, elevation, duration, and notes. Your trail history, all in one place."),
        ("chart.bar.fill", "See Your Progress",
         "Weekly distance charts, elevation totals, and personal stats help you see how far you've come."),
        ("star.fill", "Rate & Revisit",
         "Rate your hikes, mark favorites, and build a library of trails you love. No subscription required."),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [TrekTheme.forestGreen, Color(red: 0.10, green: 0.38, blue: 0.10)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        let p = pages[i]
                        VStack(spacing: 24) {
                            Image(systemName: p.icon)
                                .font(.system(size: 72))
                                .foregroundStyle(.white)
                                .accessibilityHidden(true)

                            Text(p.title)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            Text(p.body)
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
                            .animation(.easeInOut, value: page)
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
                    Text(page == pages.count - 1 ? "Start Hiking" : "Next")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(TrekTheme.sunGold, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .accessibilityLabel(page == pages.count - 1 ? "Start Hiking" : "Next page")
            }
        }
    }
}
