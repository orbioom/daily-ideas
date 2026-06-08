import SwiftUI
import SwiftData

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
    @Environment(\.modelContext) private var context
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
        .onAppear {
            Haptics.enabled = hapticsEnabled
            SeedData.installCatalogIfNeeded(context)
        }
        .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "drop.fill") }
            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
            DrinksView()
                .tabItem { Label("Drinks", systemImage: "cup.and.saucer.fill") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
        }
    }
}
