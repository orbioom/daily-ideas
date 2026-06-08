import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("slate.onboarded") private var onboarded = false
    @AppStorage("slate.haptics") private var haptics = true
    @State private var didSeed = false

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(Color(hex: 0x5E63A6))
        .onAppear {
            Haptics.enabled = haptics
            if onboarded && !didSeed {
                SeedData.seedIfNeeded(context)
                didSeed = true
            }
        }
        .onChange(of: onboarded) { _, new in
            if new && !didSeed {
                SeedData.seedIfNeeded(context)
                didSeed = true
            }
        }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            PlannerView()
                .tabItem { Label("Today", systemImage: "calendar.day.timeline.left") }
            AgendaView()
                .tabItem { Label("Agenda", systemImage: "list.bullet.rectangle") }
            TemplatesView()
                .tabItem { Label("Routines", systemImage: "square.stack.3d.up") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.pie") }
        }
    }
}
