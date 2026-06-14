import SwiftUI
import SwiftData

@main
struct SkilletApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @StateObject private var settings = AppSettings()
    @StateObject private var shopping = ShoppingState()
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: PantryItem.self, Recipe.self, RecipeIngredient.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: PantryItem.self, Recipe.self, RecipeIngredient.self, configurations: config)
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
            .environmentObject(shopping)
            .tint(Theme.accent)
        }
        .modelContainer(container)
    }
}
