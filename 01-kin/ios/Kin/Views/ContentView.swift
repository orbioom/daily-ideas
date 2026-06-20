import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var settingsQuery: [KinSettings]

    private var settings: KinSettings? { settingsQuery.first }

    var body: some View {
        if settings?.onboardingComplete == true {
            mainApp
        } else {
            OnboardingView()
        }
    }

    private var mainApp: some View {
        TabView {
            FamilyTreeView()
                .tabItem {
                    Label("Tree", systemImage: "tree.fill")
                }

            PeopleListView()
                .tabItem {
                    Label("People", systemImage: "person.3.fill")
                }

            FamilyChronicleView()
                .tabItem {
                    Label("Chronicle", systemImage: "scroll.fill")
                }

            FamilyInsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }

            KinSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(KinTheme.accent)
    }
}
