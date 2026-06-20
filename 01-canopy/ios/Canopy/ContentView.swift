import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var settings: [CanopySettings]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if settings.first?.hasCompletedOnboarding == true {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [EmissionEntry.self, CanopySettings.self], inMemory: true)
}
