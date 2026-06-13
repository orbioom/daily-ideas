import SwiftUI

struct RootView: View {
    @AppStorage("appearance") private var appearance = AppearanceMode.system.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        TabView {
            ForecastView().tabItem { Label("Runway", systemImage: "chart.line.uptrend.xyaxis") }
            CalendarView().tabItem { Label("Calendar", systemImage: "calendar") }
            MoneyView().tabItem { Label("Money", systemImage: "list.bullet.rectangle") }
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .preferredColorScheme(AppearanceMode(rawValue: appearance)?.scheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
    }
}

/// Shared helper to build a forecast from stored state.
struct ForecastContext {
    let balance: Double
    let asOf: Date
    let buffer: Double
    let currency: String

    static func current(recurring: [RecurringItem], oneOffs: [OneOffItem]) -> Forecast {
        let d = UserDefaults.standard
        let balance = d.object(forKey: "currentBalance") as? Double ?? 0
        let asOfRaw = d.object(forKey: "balanceAsOf") as? Double ?? Date().timeIntervalSince1970
        let buffer = d.object(forKey: "buffer") as? Double ?? 100
        let engine = ForecastEngine(openingBalance: balance,
                                    asOf: Date(timeIntervalSince1970: asOfRaw),
                                    recurring: recurring, oneOffs: oneOffs, buffer: buffer)
        return engine.run(days: Horizon.days)
    }
}
