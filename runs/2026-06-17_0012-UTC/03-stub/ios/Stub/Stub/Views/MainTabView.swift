import SwiftUI

/// The root tabbed experience. The CalculatorModel is owned here so the
/// Calculator and Breakdown tabs share the same live inputs, and Scenarios
/// can load a saved scenario into it.
struct MainTabView: View {
    @Environment(AppPreferences.self) private var prefs
    @State private var calc = CalculatorModel()
    @State private var selectedTab: Tab = .calculator
    @State private var didApplyDefaults = false

    enum Tab: Hashable {
        case calculator, breakdown, compare, scenarios, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            CalculatorView(calc: calc, switchToBreakdown: { selectedTab = .breakdown })
                .tabItem { Label("Calculator", systemImage: "function") }
                .tag(Tab.calculator)

            BreakdownView(calc: calc)
                .tabItem { Label("Breakdown", systemImage: "chart.pie.fill") }
                .tag(Tab.breakdown)

            CompareView()
                .tabItem { Label("Compare", systemImage: "rectangle.split.2x1") }
                .tag(Tab.compare)

            ScenariosView(loadIntoCalculator: { scenario in
                calc.load(from: scenario)
                selectedTab = .calculator
            })
            .tabItem { Label("Scenarios", systemImage: "tray.full.fill") }
            .tag(Tab.scenarios)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(StubTheme.green)
        .onAppear {
            guard !didApplyDefaults else { return }
            didApplyDefaults = true
            calc.applyDefaults(prefs)
        }
    }
}
