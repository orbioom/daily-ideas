import SwiftUI
import SwiftData

/// App appearance preference, persisted and applied app-wide.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(Color.accentColor)
        .preferredColorScheme(appearance.colorScheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
        .onChange(of: hapticsEnabled) { _, newValue in Haptics.enabled = newValue }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            JournalView()
                .tabItem { Label("Journal", systemImage: "book.closed.fill") }
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
            PromptsView()
                .tabItem { Label("Prompts", systemImage: "sparkles") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
        }
    }
}
