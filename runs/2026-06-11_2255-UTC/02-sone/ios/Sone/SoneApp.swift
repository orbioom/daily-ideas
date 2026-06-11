import SwiftUI
import SwiftData

@main
struct SoneApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootView()
                } else {
                    OnboardingView()
                }
            }
            .tint(Theme.accent)
        }
        .modelContainer(for: MeasureSession.self)
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            MeterView()
                .tabItem { Label("Meter", systemImage: "gauge.with.needle") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            GuideView()
                .tabItem { Label("Guide", systemImage: "ear.badge.waveform") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
