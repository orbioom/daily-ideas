import SwiftUI
import SwiftData

/// The app shell. Gates onboarding behind `latent.hasOnboarded`, applies the
/// chosen appearance, wires up the shared TimerEngine, and presents the five
/// feature tabs over the Orbioom page background.
struct RootView: View {
    @AppStorage("latent.hasOnboarded") private var hasOnboarded = false
    @AppStorage("latent.appearance") private var appearance = AppearancePref.system.rawValue
    @AppStorage("latent.haptics") private var hapticsEnabled = true

    @Environment(\.modelContext) private var context

    /// One timer engine for the whole app so a run keeps living as the user moves
    /// between tabs (and survives relaunch via its own persisted state).
    @StateObject private var timer = TimerEngine()

    @State private var selectedTab = 0

    var body: some View {
        Group {
            if hasOnboarded {
                tabs
            } else {
                OnboardingView {
                    SampleData.seedIfEmpty(context)
                    withAnimation(Brand.ease()) { hasOnboarded = true }
                }
            }
        }
        .tint(Brand.text)
        .preferredColorScheme((AppearancePref(rawValue: appearance) ?? .system).colorScheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
        .onChange(of: hapticsEnabled) { _, newValue in Haptics.enabled = newValue }
        .environmentObject(timer)
    }

    private var tabs: some View {
        TabView(selection: $selectedTab) {
            RecipesView()
                .tabItem { Label("Recipes", systemImage: "list.bullet.rectangle") }
                .tag(0)

            DevelopView()
                .tabItem { Label("Develop", systemImage: "timer") }
                .tag(1)

            LogView()
                .tabItem { Label("Log", systemImage: "book.closed") }
                .tag(2)

            ReferenceView()
                .tabItem { Label("Reference", systemImage: "thermometer.medium") }
                .tag(3)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(4)
        }
    }
}

/// Appearance preference persisted in @AppStorage.
enum AppearancePref: String, CaseIterable, Identifiable {
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
