import SwiftUI
import SwiftData

/// The five tabs. `Calculator` and `Amortization` share one `CalculatorModel`;
/// `AppSettings` is shared by every screen.
struct RootView: View {
    @State private var calc = CalculatorModel()
    @State private var settings = AppSettings()
    @State private var selection: Tab = .calculator
    @State private var didApplyDefaults = false

    enum Tab: Hashable {
        case calculator, amortization, scenarios, affordability, refinance
    }

    var body: some View {
        TabView(selection: $selection) {
            CalculatorView(selection: $selection)
                .tabItem { Label("Calculator", systemImage: "function") }
                .tag(Tab.calculator)

            AmortizationView()
                .tabItem { Label("Schedule", systemImage: "chart.line.downtrend.xyaxis") }
                .tag(Tab.amortization)

            ScenariosView(selection: $selection)
                .tabItem { Label("Scenarios", systemImage: "square.stack.3d.up") }
                .tag(Tab.scenarios)

            AffordabilityView()
                .tabItem { Label("Afford", systemImage: "scalemass") }
                .tag(Tab.affordability)

            RefinanceView()
                .tabItem { Label("Refinance", systemImage: "arrow.triangle.2.circlepath") }
                .tag(Tab.refinance)
        }
        .tint(Theme.accent)
        .environment(calc)
        .environment(settings)
        .onAppear {
            // Apply persisted defaults exactly once, to the initial blank-ish state.
            if !didApplyDefaults {
                didApplyDefaults = true
                calc.applyDefaults(settings)
            }
        }
    }
}
