import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("grove.onboarded") private var onboarded = false
    @AppStorage("grove.haptics") private var haptics = true

    var body: some View {
        ZStack {
            if onboarded {
                MainTabs()
            } else {
                OnboardingView(done: Binding(get: { onboarded }, set: { onboarded = $0 }))
            }
        }
        .tint(Brand.text)
        .task { FocusTag.ensureDefaults(in: context) }
        .onAppear { Haptics.enabled = haptics }
        .onChange(of: haptics) { _, v in Haptics.enabled = v }
    }
}

struct MainTabs: View {
    var body: some View {
        TabView {
            FocusView()
                .tabItem { Label("Focus", systemImage: "timer") }
            GroveView()
                .tabItem { Label("Grove", systemImage: "tree.fill") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            TagsView()
                .tabItem { Label("Tags", systemImage: "tag.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
