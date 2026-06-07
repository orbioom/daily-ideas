import SwiftUI
import SwiftData

/// Top-level shell. Gates onboarding behind an @AppStorage flag, then presents
/// the main TabView. Applies the user's appearance and haptics preferences.
struct RootView: View {
    @AppStorage("gauge.hasOnboarded") private var hasOnboarded = false
    @AppStorage("gauge.appearance") private var appearance = AppearanceMode.system.rawValue
    @AppStorage("gauge.haptics") private var hapticsEnabled = true

    @Environment(\.modelContext) private var context

    var body: some View {
        ZStack {
            Brand.pageBackground
            if hasOnboarded {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .tint(Brand.text)
        .preferredColorScheme(resolvedScheme)
        .animation(Brand.ease(), value: hasOnboarded)
        .onAppear { Haptics.enabled = hapticsEnabled }
        .onChange(of: hapticsEnabled) { _, newValue in Haptics.enabled = newValue }
    }

    private var resolvedScheme: ColorScheme? {
        AppearanceMode(rawValue: appearance)?.colorScheme
    }
}

/// The four feature tabs.
struct MainTabView: View {
    var body: some View {
        TabView {
            InstrumentsView()
                .tabItem { Label("Instruments", systemImage: "guitars") }
            CalculatorView()
                .tabItem { Label("Calculator", systemImage: "function") }
            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

/// Appearance preference stored as a String raw value.
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

/// Weight unit preference for displaying tensions.
enum WeightUnit: String, CaseIterable, Identifiable {
    case pounds, kilograms
    var id: String { rawValue }
    var label: String { self == .pounds ? "Pounds (lb)" : "Kilograms (kg)" }
    var short: String { self == .pounds ? "lb" : "kg" }

    /// Converts a pounds value into the selected unit.
    func value(fromLb lb: Double) -> Double {
        self == .pounds ? lb : lb * TensionEngine.lbToKg
    }

    /// Formats a pounds value with this unit's suffix.
    func format(fromLb lb: Double, decimals: Int = 1) -> String {
        String(format: "%.\(decimals)f %@", value(fromLb: lb), short)
    }
}
