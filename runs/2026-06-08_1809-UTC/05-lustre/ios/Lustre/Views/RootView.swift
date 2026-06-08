import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("lustre.onboarded") private var onboarded = false
    @AppStorage("lustre.haptics") private var haptics = true

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(Color(hex: 0x9E7BA8))
        .onAppear { Haptics.enabled = haptics }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sparkles") }
            RoutinesView()
                .tabItem { Label("Routines", systemImage: "list.number") }
            ShelfView()
                .tabItem { Label("Shelf", systemImage: "cabinet") }
            JournalView()
                .tabItem { Label("Journal", systemImage: "chart.line.uptrend.xyaxis") }
        }
    }
}
