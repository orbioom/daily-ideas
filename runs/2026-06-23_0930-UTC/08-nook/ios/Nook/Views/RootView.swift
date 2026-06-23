import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView(hasOnboarded: $hasOnboarded)
                    .transition(.opacity)
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            DueDashboardView()
                .tabItem { Label("Due", systemImage: "clock.badge.exclamationmark") }

            TasksView()
                .tabItem { Label("Tasks", systemImage: "checklist") }

            RoomsView()
                .tabItem { Label("Rooms", systemImage: "square.split.bottomrightquarter") }

            EquipmentView()
                .tabItem { Label("Equipment", systemImage: "wrench.and.screwdriver") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    RootView()
        .previewModelContainer()
}
