import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [HaloSettings]

    @State private var engine = BinauralEngine()
    @State private var showPlayer = false
    @State private var selectedPreset: HaloPreset?

    private var settings: HaloSettings {
        if let s = settingsQuery.first { return s }
        let s = HaloSettings()
        modelContext.insert(s)
        return s
    }

    var body: some View {
        Group {
            if !settings.hasCompletedOnboarding {
                OnboardingView(settings: settings)
            } else {
                MainTabView(engine: engine)
                    .fullScreenCover(isPresented: $showPlayer) {
                        if let preset = selectedPreset {
                            PlayerView(engine: engine, preset: preset)
                        }
                    }
            }
        }
        .preferredColorScheme(.dark)
    }
}
