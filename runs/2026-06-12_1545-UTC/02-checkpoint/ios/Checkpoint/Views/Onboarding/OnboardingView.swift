import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("square.stack.3d.up.fill", "Tame the pile",
         "Checkpoint is the native home for your gaming backlog. Track every game across every platform — wishlist, backlog, playing, beaten and 100%."),
        ("dice.fill", "Never wonder what to play",
         "Stuck choosing? Let Checkpoint shuffle your backlog and hand you your next game, weighted by your priorities and quick wins."),
        ("chart.pie.fill", "See where your time and money go",
         "Hours played, cost-per-hour, completion rate and your taste in genres — clean stats, fully offline, no account, no ads.")
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
                                .font(.system(size: 78))
                                .foregroundStyle(Theme.accent)
                                .accessibilityHidden(true)
                            Text(pages[i].title)
                                .font(.system(.largeTitle, design: .rounded).weight(.bold))
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
                    Text(page < pages.count - 1 ? "Continue" : "Start your library")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }
}
