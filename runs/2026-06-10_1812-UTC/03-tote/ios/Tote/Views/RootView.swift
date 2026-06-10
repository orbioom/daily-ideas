import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("didSeed") private var didSeed = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("appearance") private var appearance = "system"

    var body: some View {
        ZStack {
            if hasOnboarded { MainTabView() } else { OnboardingView() }
        }
        .task { seedIfNeeded() }
        .onAppear { Haptics.enabled = hapticsEnabled }
        .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
    }

    private func seedIfNeeded() {
        guard !didSeed else { return }
        let count = (try? context.fetchCount(FetchDescriptor<GroceryList>())) ?? 0
        if count == 0 {
            let list = GroceryList(name: "Groceries", sortIndex: 0)
            context.insert(list)
            try? context.save()
        }
        didSeed = true
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            ListsView()
                .tabItem { Label("Lists", systemImage: "checklist") }
            RecipesView()
                .tabItem { Label("Recipes", systemImage: "book.closed.fill") }
            StaplesView()
                .tabItem { Label("Staples", systemImage: "star.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Brand.text)
    }
}
