import SwiftUI
import SwiftData

/// The app shell: gates onboarding, wires global prefs (appearance, haptics),
/// and hosts the five-tab navigation over the shared page background.
struct RootView: View {
    @AppStorage("ramp.hasOnboarded") private var hasOnboarded = false
    @AppStorage("ramp.appearance") private var appearance = AppearanceMode.system.rawValue
    @AppStorage("ramp.hapticsEnabled") private var hapticsEnabled = true

    @Environment(\.modelContext) private var context

    private var colorScheme: ColorScheme? {
        AppearanceMode(rawValue: appearance)?.colorScheme
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            if hasOnboarded {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView {
                    SampleData.seedIfEmpty(context)
                    withAnimation(Brand.ease()) { hasOnboarded = true }
                }
                .transition(.opacity)
            }
        }
        .tint(Brand.text)
        .preferredColorScheme(colorScheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
        .onChange(of: hapticsEnabled) { _, new in Haptics.enabled = new }
    }
}

/// The five primary tabs.
struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
            RidesView()
                .tabItem { Label("Rides", systemImage: "bicycle") }
            TrendsView()
                .tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }
            FTPView()
                .tabItem { Label("FTP", systemImage: "bolt") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

/// Appearance preference stored as a String rawValue.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
