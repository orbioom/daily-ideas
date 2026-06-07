import SwiftUI
import SwiftData

/// App appearance preference, persisted as a String rawValue.
enum AppearancePref: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// The root: gates onboarding, hosts the tab bar, applies global appearance and
/// haptics preferences, and lays everything over the brand page background.
struct RootView: View {
    @AppStorage("datum.hasOnboarded") private var hasOnboarded = false
    @AppStorage("datum.appearance") private var appearanceRaw = AppearancePref.system.rawValue
    @AppStorage("datum.hapticsEnabled") private var hapticsEnabled = true

    private var appearance: AppearancePref {
        AppearancePref(rawValue: appearanceRaw) ?? .system
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            if hasOnboarded {
                MainTabs()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .tint(Brand.text)
        .preferredColorScheme(appearance.colorScheme)
        .animation(Brand.ease(), value: hasOnboarded)
        .onAppear { Haptics.enabled = hapticsEnabled }
        .onChange(of: hapticsEnabled) { _, newValue in Haptics.enabled = newValue }
    }
}

/// The four primary tabs.
struct MainTabs: View {
    var body: some View {
        TabView {
            FlightsView()
                .tabItem { Label("Flights", systemImage: "airplane") }
            AircraftListView()
                .tabItem { Label("Aircraft", systemImage: "airplane.circle") }
            ToolsView()
                .tabItem { Label("Tools", systemImage: "slider.horizontal.3") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
