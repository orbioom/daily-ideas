import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [ScriptSettings]

    private var settings: ScriptSettings? { allSettings.first }

    var body: some View {
        Group {
            if let s = settings, s.hasCompletedOnboarding {
                ProjectListView()
                    .preferredColorScheme(colorScheme(for: s.colorScheme))
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            if allSettings.isEmpty {
                let s = ScriptSettings()
                modelContext.insert(s)
            }
        }
    }

    private func colorScheme(for mode: String) -> ColorScheme? {
        switch mode {
        case "dark": return .dark
        case "light": return .light
        default: return nil
        }
    }
}
