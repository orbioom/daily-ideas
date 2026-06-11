import SwiftUI

struct RootView: View {
    @AppStorage("murmur.onboardingDone") private var onboardingDone = false

    var body: some View {
        if onboardingDone {
            TabView {
                RecordView()
                    .tabItem { Label("Record", systemImage: "mic.fill") }
                JournalView()
                    .tabItem { Label("Journal", systemImage: "book.fill") }
                MurmurCalendarView()
                    .tabItem { Label("Calendar", systemImage: "calendar") }
                SearchView()
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
                MurmurSettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
            .tint(MurmurTheme.accent)
        } else {
            MurmurOnboardingView()
        }
    }
}
