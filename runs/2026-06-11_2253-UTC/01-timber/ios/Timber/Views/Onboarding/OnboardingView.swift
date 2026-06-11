import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("moon.zzz.fill", "Find out if you snore",
         "Put Timber on your nightstand, plugged in, and it listens for snoring while you sleep. In the morning you get a Snore Score, a timeline of the night, and every episode classified mild, loud, or epic."),
        ("lock.shield.fill", "Private by design",
         "Everything happens on your iPhone. Audio is analyzed live and immediately discarded — Timber stores numbers, never recordings, and nothing ever leaves your device."),
        ("leaf.fill", "Test remedies like a scientist",
         "Tag each night with what you tried — mouth tape, no alcohol, side sleeping. After a few nights Timber shows which remedies actually quiet you down."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    VStack(spacing: 20) {
                        Image(systemName: pages[i].icon)
                            .font(.system(size: 64))
                            .foregroundStyle(Theme.amber)
                            .accessibilityHidden(true)
                        Text(pages[i].title)
                            .font(.title.weight(.bold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.inkPrimary(scheme))
                        Text(pages[i].body)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.inkSecondary(scheme))
                            .padding(.horizontal, 28)
                    }
                    .tag(i)
                    .padding(.bottom, 40)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < pages.count - 1 {
                    if reduceMotion { page += 1 }
                    else { withAnimation { page += 1 } }
                } else {
                    Haptics.success()
                    hasOnboarded = true
                }
            } label: {
                Text(page < pages.count - 1 ? "Continue" : "Start sleeping smarter")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.amber)
            .foregroundStyle(.black)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .background(Theme.background(scheme))
    }
}
