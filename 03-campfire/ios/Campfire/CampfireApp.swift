import SwiftUI
import SwiftData

@main
struct CampfireApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [
                    CampTrip.self,
                    GearItem.self,
                    MealPlan.self,
                    NatureLog.self,
                    CampSettings.self
                ])
        }
    }
}
