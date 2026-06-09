import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var kids: [Kid]
    @AppStorage("sprout.onboarded") private var onboarded = false
    @AppStorage("sprout.haptics") private var haptics = true
    @AppStorage("sprout.autoAllowance") private var autoAllowance = true

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded { MainTabView() } else { OnboardingView() }
        }
        .tint(Color(hex: 0x6E9E4E))
        .onAppear {
            Haptics.enabled = haptics
            if onboarded && autoAllowance {
                ChoreEngine.creditDueAllowances(kids, context: context)
            }
        }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "checklist") }
            KidsView()
                .tabItem { Label("Kids", systemImage: "person.2.fill") }
            ChoresView()
                .tabItem { Label("Chores", systemImage: "list.bullet.rectangle.portrait") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
