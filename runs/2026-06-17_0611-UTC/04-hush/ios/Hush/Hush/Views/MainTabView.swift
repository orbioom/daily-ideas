import SwiftUI

/// The root tabbed experience: Mixer, Mixes, Timer, Sessions, Settings.
struct MainTabView: View {
    var body: some View {
        TabView {
            MixerView()
                .tabItem { Label("Mixer", systemImage: "slider.horizontal.3") }

            MixesView()
                .tabItem { Label("Mixes", systemImage: "square.stack.3d.up.fill") }

            TimerView()
                .tabItem { Label("Timer", systemImage: "moon.zzz.fill") }

            SessionsView()
                .tabItem { Label("Sessions", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(HushTheme.teal)
    }
}
