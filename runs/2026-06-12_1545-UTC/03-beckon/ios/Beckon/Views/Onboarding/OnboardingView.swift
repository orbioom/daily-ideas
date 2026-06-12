import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("sparkles", "Welcome to Beckon",
         "Beckon is a calm home for the 369 method — the manifestation ritual loved by millions. Choose what you want to call in, then write it into being."),
        ("sun.and.horizon.fill", "Three, six, nine",
         "Write your affirmation 3 times in the morning, 6 in the afternoon, and 9 at night. The repetition focuses your intention and builds a daily practice."),
        ("lock.shield", "Yours alone",
         "Your intentions and journal live only on your iPhone. No account, no feed, no ads — just you and what you're calling toward.")
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
                                .foregroundStyle(Theme.goldGradient)
                                .accessibilityHidden(true)
                            Text(pages[i].title)
                                .font(.system(.largeTitle, design: .serif).weight(.bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.textPrimary)
                            Text(pages[i].body)
                                .font(.body)
                                .multilineTextAlignment(.center)
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
                    if page < pages.count - 1 { withAnimation { page += 1 } }
                    else { hasOnboarded = true }
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
