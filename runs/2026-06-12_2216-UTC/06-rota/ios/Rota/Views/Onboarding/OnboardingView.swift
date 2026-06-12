import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        (
            "arrow.triangle.2.circlepath",
            "Rota",
            "Your shift calendar, finally legible. Define your rotation once — 4-on-4-off, day/night cycles, anything — and every month fills itself in, years ahead."
        ),
        (
            "calendar.badge.clock",
            "Real Life Happens",
            "Swapped with a colleague? Picked up overtime? Tap any day to change just that day — the rotation underneath keeps running, and changed days are marked."
        ),
        (
            "banknote.fill",
            "Know Your Pay",
            "Put an hourly rate on each shift type and Rota projects paid hours and earnings for any week or month — overnight shifts and unpaid breaks handled correctly."
        ),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.15, blue: 0.20), Color(red: 0.05, green: 0.08, blue: 0.11)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 20) {
                            Image(systemName: pages[index].icon)
                                .font(.system(size: 56))
                                .foregroundStyle(RotaTheme.amber)
                                .accessibilityHidden(true)
                            Text(pages[index].title)
                                .font(.largeTitle.weight(.bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                            Text(pages[index].body)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.82))
                                .padding(.horizontal, 30)
                        }
                        .tag(index)
                        .padding(.bottom, 40)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    Haptics.tap()
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        hasOnboarded = true
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Set Up My Rotation")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(RotaTheme.amber)
                .foregroundStyle(.black)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
    }
}
