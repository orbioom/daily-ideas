import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("static.hasOnboarded") private var hasOnboarded = false
    @AppStorage("static.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("static.appearance") private var appearance = "system"
    @Query private var tables: [ApneaTable]

    private var scheme: ColorScheme? {
        switch appearance { case "light": return .light; case "dark": return .dark; default: return nil }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            if hasOnboarded {
                TabView {
                    TablesView()
                        .tabItem { Label("Train", systemImage: "lungs") }
                    LogView()
                        .tabItem { Label("Log", systemImage: "list.bullet.rectangle") }
                    ProgressView2()
                        .tabItem { Label("Progress", systemImage: "chart.xyaxis.line") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                }
                .tint(Brand.text)
            } else {
                OnboardingView {
                    if tables.isEmpty { SampleData.seed(into: context) }
                    hasOnboarded = true
                }
            }
        }
        .preferredColorScheme(scheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
    }
}
