import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var settingsQuery: [UserSettings]
    @Environment(\.modelContext) private var modelContext

    private var settings: UserSettings {
        if let s = settingsQuery.first { return s }
        let s = UserSettings()
        modelContext.insert(s)
        return s
    }

    var body: some View {
        Group {
            if settingsQuery.first?.hasCompletedOnboarding == true {
                MainTabView()
            } else if settingsQuery.isEmpty {
                // Loading — seed settings
                ProgressView()
                    .onAppear { seedSettings() }
            } else {
                OnboardingView()
            }
        }
    }

    private func seedSettings() {
        if settingsQuery.isEmpty {
            let s = UserSettings()
            modelContext.insert(s)
        }
    }
}
