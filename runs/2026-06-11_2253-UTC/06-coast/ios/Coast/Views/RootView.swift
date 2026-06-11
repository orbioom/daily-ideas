import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("appearance") private var appearance = "system"
    @Query private var profiles: [Profile]

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Plan", systemImage: "sailboat.fill") }
            ProjectionView()
                .tabItem { Label("Projection", systemImage: "chart.xyaxis.line") }
            ProgressTabView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
            MilestonesView()
                .tabItem { Label("Milestones", systemImage: "flag.checkered") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.teal)
        .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
        .task { ensureProfile() }
    }

    private func ensureProfile() {
        if profiles.isEmpty {
            context.insert(Profile())
        }
    }
}

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("sailboat.fill", "Find your finish line",
         "Coast turns one simple idea — the 4% rule — into your personal number: the portfolio that lets work become optional. Enter a few figures, see your FI date."),
        ("wind", "Discover Coast FI",
         "The milestone most apps miss: the point where you can stop investing entirely and still retire on time, letting compound growth coast you home. Coast tells you exactly when you cross it."),
        ("lock.shield.fill", "Your numbers, your phone",
         "No bank logins, no account, no data leaving your device. Just honest math and a calm picture of your path to freedom."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    VStack(spacing: 20) {
                        Image(systemName: pages[i].icon)
                            .font(.system(size: 60))
                            .foregroundStyle(Theme.teal)
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
                Text(page < pages.count - 1 ? "Continue" : "Chart my course")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.teal)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .background(Theme.background(scheme))
    }
}
