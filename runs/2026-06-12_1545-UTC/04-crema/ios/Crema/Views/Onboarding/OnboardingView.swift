import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("cup.and.saucer.fill", "Brew it better, every time",
         "Crema is your espresso and coffee dial-in companion. Log every shot and pour, and stop guessing your way to a great cup."),
        ("slider.horizontal.3", "Dial in with confidence",
         "Tell Crema whether a shot tasted sour, balanced or bitter and it tells you exactly what to change next — finer, coarser, longer, shorter."),
        ("bag.fill", "Know your beans",
         "Track each bag's freshness window and find the recipe that made it sing. All on your iPhone — no account, no subscription paywall on your own data.")
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
                                .font(.system(size: 74))
                                .foregroundStyle(Theme.cremaGradient)
                                .accessibilityHidden(true)
                            Text(pages[i].title)
                                .font(.system(.largeTitle, design: .rounded).weight(.bold))
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
                    Text(page < pages.count - 1 ? "Continue" : "Start brewing")
                        .font(.headline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(Theme.accent).controlSize(.large)
                .padding(.horizontal).padding(.bottom, 30)
            }
        }
    }
}
