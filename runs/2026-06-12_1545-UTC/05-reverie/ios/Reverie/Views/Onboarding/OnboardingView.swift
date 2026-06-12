import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("moon.stars.fill", "Catch your dreams",
         "You forget half a dream within five minutes of waking. Reverie is built for fast capture — log it before it fades."),
        ("sparkle.magnifyingglass", "Find your dream signs",
         "Reverie spots the people, places and themes that recur in your dreams. These are your cues to realize you're dreaming."),
        ("sparkles", "Learn to go lucid",
         "Reality-check reminders and a technique library help you become aware inside your dreams. Everything stays private on your iPhone.")
    ]

    var body: some View {
        ZStack {
            Theme.bgPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 22) {
                            Spacer()
                            Image(systemName: pages[i].symbol)
                                .font(.system(size: 72))
                                .foregroundStyle(Theme.moonGradient)
                                .accessibilityHidden(true)
                            Text(pages[i].title)
                                .font(.system(.largeTitle, design: .serif).weight(.bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.textPrimary)
                            Text(pages[i].body)
                                .font(.body).multilineTextAlignment(.center)
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.horizontal, 32)
                            Spacer()
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    Haptics.success()
                    if page < pages.count - 1 { withAnimation { page += 1 } } else { hasOnboarded = true }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Begin")
                        .font(.headline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(Theme.accent).controlSize(.large)
                .padding(.horizontal).padding(.bottom, 30)
            }
        }
    }
}
