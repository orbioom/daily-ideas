import SwiftUI

struct RootView: View {
    @AppStorage("appearance") private var appearance = "system"
    @State private var engine = SpeechEngine()

    var body: some View {
        TabView {
            PracticeView()
                .tabItem { Label("Practice", systemImage: "mic.fill") }
            SessionsView()
                .tabItem { Label("Sessions", systemImage: "list.bullet.rectangle.fill") }
            ProgressTabView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
            CoachView()
                .tabItem { Label("Coach", systemImage: "graduationcap.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.violet)
        .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
        .environment(engine)
    }
}

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("mic.fill", "Practice out loud",
         "Pick a prompt — interview answer, toast, pitch — and talk. Podium transcribes you live and shows your pace and filler words as you speak."),
        ("waveform.badge.magnifyingglass", "See what listeners hear",
         "After each take: a delivery score, your um/uh/like count, words per minute, vocabulary variety, and your transcript with every filler highlighted."),
        ("lock.shield.fill", "All on your iPhone",
         "Transcription runs on-device. No audio or text ever leaves your phone — practice your worst takes in total privacy."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    VStack(spacing: 20) {
                        Image(systemName: pages[i].icon)
                            .font(.system(size: 60))
                            .foregroundStyle(Theme.violet)
                            .accessibilityHidden(true)
                        Text(pages[i].title)
                            .font(Theme.display(28))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.ink(scheme))
                        Text(pages[i].body)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.inkSoft(scheme))
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
                Text(page < pages.count - 1 ? "Continue" : "Take the stage")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.violet)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .background(Theme.background(scheme))
    }
}
