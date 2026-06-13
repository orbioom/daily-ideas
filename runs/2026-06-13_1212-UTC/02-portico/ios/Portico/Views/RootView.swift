import SwiftUI

/// The four feature tabs plus Settings. Each tab owns its own NavigationStack.
struct RootView: View {
    @State private var pro = ProStore()

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
            ReflectView()
                .tabItem { Label("Reflect", systemImage: "square.and.pencil") }
            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }
            PathView()
                .tabItem { Label("Path", systemImage: "chart.line.uptrend.xyaxis") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environment(pro)
        .tint(Theme.accent)
    }
}
