import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var settingsQ: [FableSettings]

    var body: some View {
        if settingsQ.first?.onboardingComplete == true {
            mainTabs
        } else {
            FableOnboardingView()
        }
    }

    private var mainTabs: some View {
        TabView {
            StoriesListView()
                .tabItem { Label("Stories", systemImage: "book.fill") }

            TemplatesGalleryView()
                .tabItem { Label("Templates", systemImage: "doc.text.fill") }

            FableSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(FableTheme.accent)
    }
}
