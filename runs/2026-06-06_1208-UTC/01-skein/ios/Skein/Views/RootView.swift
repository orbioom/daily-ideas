import SwiftUI
import SwiftData

/// Hosts onboarding gating, first-run seeding, and the main tab bar.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("didSeed") private var didSeed = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    @State private var selection = 0

    var body: some View {
        ZStack {
            Brand.pageBackground
            if hasOnboarded {
                TabView(selection: $selection) {
                    ProjectsView()
                        .tabItem { Label("Projects", systemImage: "square.stack.3d.up") }
                        .tag(0)
                    StashView()
                        .tabItem { Label("Stash", systemImage: "circle.grid.2x2") }
                        .tag(1)
                    ToolsView()
                        .tabItem { Label("Tools", systemImage: "ruler") }
                        .tag(2)
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                        .tag(3)
                }
                .tint(Brand.text)
            } else {
                OnboardingView { hasOnboarded = true }
                    .transition(.opacity)
            }
        }
        .animation(Brand.ease(), value: hasOnboarded)
        .task {
            Haptics.enabled = hapticsEnabled
            seedIfNeeded()
        }
        .onChange(of: hapticsEnabled) { _, new in Haptics.enabled = new }
    }

    private func seedIfNeeded() {
        guard !didSeed else { return }
        SampleData.seed(into: context)
        didSeed = true
    }
}
