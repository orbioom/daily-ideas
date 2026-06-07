import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("bench.hasOnboarded") private var hasOnboarded = false
    @AppStorage("bench.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("bench.appearance") private var appearance = "system"
    @Query private var parts: [Component]

    private var scheme: ColorScheme? {
        switch appearance { case "light": return .light; case "dark": return .dark; default: return nil }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            if hasOnboarded {
                TabView {
                    CalculatorsView()
                        .tabItem { Label("Calculators", systemImage: "function") }
                    NotebookView()
                        .tabItem { Label("Notebook", systemImage: "book") }
                    PartsView()
                        .tabItem { Label("Parts", systemImage: "cpu") }
                    ReferenceView()
                        .tabItem { Label("Reference", systemImage: "list.bullet.rectangle.portrait") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                }
                .tint(Brand.text)
            } else {
                OnboardingView {
                    if parts.isEmpty { SampleData.seed(into: context) }
                    hasOnboarded = true
                }
            }
        }
        .preferredColorScheme(scheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
    }
}
