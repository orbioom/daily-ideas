import SwiftUI
import SwiftData

@main
struct PlateApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([FoodItem.self, DiaryEntry.self, UserGoal.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: config) {
            container = c
        } else {
            container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
