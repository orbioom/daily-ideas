import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query private var allPrefs: [LocalePrefs]
    @State private var page = 0

    private var prefs: LocalePrefs {
        if let p = allPrefs.first { return p }
        let p = LocalePrefs(); context.insert(p); return p
    }

    var body: some View {
        TabView(selection: $page) {
            OnboardingPage(
                symbol: "globe",
                color: .blue,
                title: "Speak the World",
                body: "Instantly access essential phrases in 6 languages — no internet required."
            )
            .tag(0)

            OnboardingPage(
                symbol: "speaker.wave.2.fill",
                color: .green,
                title: "Hear It Right",
                body: "Tap any phrase to hear native-style pronunciation so you sound like a local."
            )
            .tag(1)

            VStack(spacing: 32) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.red)

                VStack(spacing: 12) {
                    Text("Save Your Favorites")
                        .font(.title.bold())
                    Text("Bookmark the phrases you use most and find them instantly when you need them.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Button {
                    prefs.hasSeenOnboarding = true
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 32)
                }
            }
            .tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .animation(.easeInOut, value: page)
    }
}

private struct OnboardingPage: View {
    let symbol: String
    let color: Color
    let title: String
    let body: String

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: symbol)
                .font(.system(size: 64))
                .foregroundStyle(color)

            VStack(spacing: 12) {
                Text(title)
                    .font(.title.bold())
                Text(body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding()
    }
}
