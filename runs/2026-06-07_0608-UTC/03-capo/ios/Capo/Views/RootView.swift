import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("capo.hasOnboarded") private var hasOnboarded = false
    @AppStorage("capo.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("capo.appearance") private var appearance = "system"
    @Query private var songs: [Song]

    private var scheme: ColorScheme? {
        switch appearance { case "light": return .light; case "dark": return .dark; default: return nil }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            if hasOnboarded {
                TabView {
                    SongsView()
                        .tabItem { Label("Songs", systemImage: "music.note.list") }
                    SetlistsView()
                        .tabItem { Label("Setlists", systemImage: "list.number") }
                    ToolsView()
                        .tabItem { Label("Tools", systemImage: "slider.horizontal.3") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                }
                .tint(Brand.text)
            } else {
                OnboardingView {
                    if songs.isEmpty { SampleData.seed(into: context) }
                    hasOnboarded = true
                }
            }
        }
        .preferredColorScheme(scheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
    }
}
