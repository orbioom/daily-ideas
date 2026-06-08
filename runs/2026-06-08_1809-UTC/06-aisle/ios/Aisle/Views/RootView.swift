import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var weddings: [Wedding]
    @AppStorage("aisle.haptics") private var haptics = true

    var body: some View {
        ZStack {
            Brand.pageBackground
            if let wedding = weddings.first {
                MainTabView(wedding: wedding)
            } else {
                OnboardingView()
            }
        }
        .tint(Color(hex: 0xB07A8C))
        .onAppear { Haptics.enabled = haptics }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
    }
}

struct MainTabView: View {
    let wedding: Wedding

    var body: some View {
        TabView {
            OverviewView(wedding: wedding)
                .tabItem { Label("Overview", systemImage: "heart.text.square") }
            GuestsView(wedding: wedding)
                .tabItem { Label("Guests", systemImage: "person.2") }
            BudgetView(wedding: wedding)
                .tabItem { Label("Budget", systemImage: "dollarsign.circle") }
            ChecklistView()
                .tabItem { Label("Checklist", systemImage: "checklist") }
        }
    }
}
