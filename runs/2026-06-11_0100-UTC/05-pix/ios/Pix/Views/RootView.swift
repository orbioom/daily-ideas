import SwiftUI

struct RootView: View {
    @AppStorage("pix.onboardingDone") private var onboardingDone = false

    var body: some View {
        if onboardingDone {
            TabView {
                HomeView()
                    .tabItem { Label("Play", systemImage: "square.grid.3x3.fill") }
                ArchiveView()
                    .tabItem { Label("Archive", systemImage: "chart.bar.fill") }
                PixSettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
            .tint(PixTheme.accent)
        } else {
            OnboardingView()
        }
    }
}
