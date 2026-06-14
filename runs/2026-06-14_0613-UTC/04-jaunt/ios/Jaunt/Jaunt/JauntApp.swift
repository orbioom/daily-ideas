import SwiftUI
import SwiftData

@main
struct JauntApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @StateObject private var settings = AppSettings()
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Trip.self, TripDay.self, ItineraryItem.self, PackItem.self, Expense.self)
        } catch {
            let c = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Trip.self, TripDay.self, ItineraryItem.self, PackItem.self, Expense.self, configurations: c)
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(settings)
            .tint(Theme.accent)
        }
        .modelContainer(container)
    }
}
