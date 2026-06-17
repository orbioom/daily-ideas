import SwiftUI

/// The root tabbed experience: Calculator, Schedule, Affordability, Refinance, Scenarios, Settings.
struct MainTabView: View {
    var body: some View {
        TabView {
            CalculatorView()
                .tabItem { Label("Calculator", systemImage: "house.fill") }

            ScheduleView()
                .tabItem { Label("Schedule", systemImage: "list.bullet.rectangle") }

            AffordabilityView()
                .tabItem { Label("Afford", systemImage: "dollarsign.circle.fill") }

            RefinanceView()
                .tabItem { Label("Refi", systemImage: "arrow.left.arrow.right") }

            ScenariosView()
                .tabItem { Label("Scenarios", systemImage: "square.stack.3d.up.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(AbodeTheme.accent)
    }
}
