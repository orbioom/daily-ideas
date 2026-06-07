import SwiftUI
import SwiftData

/// The appearance preference, persisted as a raw string in @AppStorage.
enum AppAppearance: String, CaseIterable, Identifiable {
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

/// Root of the app. Gates onboarding behind @AppStorage, then shows the four
/// feature tabs. Owns the global preferences that affect every screen
/// (appearance, haptics) and applies the page background and tint.
struct RootView: View {
    @AppStorage("apogee.hasOnboarded") private var hasOnboarded = false
    @AppStorage("apogee.haptics") private var haptics = true
    @AppStorage("apogee.appearance") private var appearanceRaw = AppAppearance.system.rawValue

    @Environment(\.modelContext) private var context

    private var appearance: AppAppearance {
        AppAppearance(rawValue: appearanceRaw) ?? .system
    }

    var body: some View {
        ZStack {
            if hasOnboarded {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(Brand.ease(), value: hasOnboarded)
        .tint(Brand.text)
        .preferredColorScheme(appearance.colorScheme)
        .onAppear { Haptics.enabled = haptics }
        .onChange(of: haptics) { _, newValue in Haptics.enabled = newValue }
    }
}

/// The four primary tabs. Each tab owns its own NavigationStack.
struct MainTabView: View {
    var body: some View {
        TabView {
            RocketsView()
                .tabItem { Label("Rockets", systemImage: "airplane.departure") }
            MotorsView()
                .tabItem { Label("Motors", systemImage: "flame") }
            FlightsView()
                .tabItem { Label("Flights", systemImage: "list.bullet.clipboard") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
