import SwiftUI
import SwiftData

@main
struct GlyphApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                RootTabView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(for: [SavedCode.self, ScanRecord.self])
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            CreateView()
                .tabItem { Label("Create", systemImage: "qrcode") }
            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }
            ScanView()
                .tabItem { Label("Scan", systemImage: "viewfinder") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(GlyphTheme.mint)
    }
}
