import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("cone.hasOnboarded") private var hasOnboarded = false
    @AppStorage("cone.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("cone.appearance") private var appearance = "system"
    @Query private var glazes: [Glaze]

    private var scheme: ColorScheme? {
        switch appearance { case "light": return .light; case "dark": return .dark; default: return nil }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            if hasOnboarded {
                TabView {
                    GlazesView()
                        .tabItem { Label("Glazes", systemImage: "drop.fill") }
                    FiringsView()
                        .tabItem { Label("Firings", systemImage: "flame.fill") }
                    PiecesView()
                        .tabItem { Label("Pieces", systemImage: "square.stack.3d.up") }
                    ReferenceView()
                        .tabItem { Label("Reference", systemImage: "thermometer.medium") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                }
                .tint(Brand.text)
            } else {
                OnboardingView {
                    if glazes.isEmpty { SampleData.seed(into: context) }
                    hasOnboarded = true
                }
            }
        }
        .preferredColorScheme(scheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
    }
}
