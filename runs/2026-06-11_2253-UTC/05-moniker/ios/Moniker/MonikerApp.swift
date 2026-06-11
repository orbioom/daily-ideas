import SwiftUI
import SwiftData

@main
struct MonikerApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootView()
                } else {
                    OnboardingView()
                }
            }
        }
        .modelContainer(for: [Verdict.self])
    }
}

struct RootView: View {
    @AppStorage("appearance") private var appearance = "system"

    var body: some View {
        TabView {
            SwipeView()
                .tabItem { Label("Swipe", systemImage: "hand.draw.fill") }
            MatchesView()
                .tabItem { Label("Matches", systemImage: "heart.fill") }
            BrowseView()
                .tabItem { Label("Browse", systemImage: "magnifyingglass") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.pie.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.blush)
        .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
    }
}

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("partnerAName") private var partnerAName = ""
    @AppStorage("partnerBName") private var partnerBName = ""
    @AppStorage("babyLastName") private var babyLastName = ""
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                infoPage(icon: "hand.draw.fill", title: "Swipe on names, together",
                         body: "One phone, two opinions. Each of you swipes through 230+ curated names — like, pass, or love. No accounts, no invites, nothing leaves this device.")
                    .tag(0)
                infoPage(icon: "heart.fill", title: "Matches feel like magic",
                         body: "When you both like a name, it lands on your shared shortlist — ranked by how hard you both fell for it. Every name shows its origin and meaning.")
                    .tag(1)
                namesPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < 2 {
                    if reduceMotion { page += 1 }
                    else { withAnimation { page += 1 } }
                } else {
                    Haptics.success()
                    hasOnboarded = true
                }
            } label: {
                Text(page < 2 ? "Continue" : "Start swiping")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.blush)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .background(Theme.background(scheme))
    }

    private func infoPage(icon: String, title: String, body bodyText: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(Theme.blush)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.display(28))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink(scheme))
            Text(bodyText)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.inkSoft(scheme))
                .padding(.horizontal, 28)
        }
        .padding(.bottom, 40)
    }

    private var namesPage: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 54))
                .foregroundStyle(Theme.sky)
                .accessibilityHidden(true)
            Text("Who's choosing?")
                .font(Theme.display(28))
                .foregroundStyle(Theme.ink(scheme))
            VStack(spacing: 12) {
                TextField("Partner 1 name (e.g. Sam)", text: $partnerAName)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                TextField("Partner 2 name (e.g. Alex)", text: $partnerBName)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                TextField("Baby's last name (optional)", text: $babyLastName)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
            }
            .padding(.horizontal, 32)
            Text("You can change these anytime in Settings.")
                .font(.caption)
                .foregroundStyle(Theme.inkSoft(scheme))
        }
        .padding(.bottom, 40)
    }
}
