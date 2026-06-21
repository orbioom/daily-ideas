import SwiftUI
import SwiftData

@main
struct InkApp: App {
    var body: some Scene {
        WindowGroup {
            InkRootView()
                .modelContainer(for: [TattooIdea.self, TattooArtist.self, TattooAppointment.self, InkSettings.self])
        }
    }
}

struct InkRootView: View {
    @Query private var settingsList: [InkSettings]

    var body: some View {
        if settingsList.first?.hasCompletedOnboarding == true {
            InkContentView()
        } else {
            InkOnboardingView()
        }
    }
}
