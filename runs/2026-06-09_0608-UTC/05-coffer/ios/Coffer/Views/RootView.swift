import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("coffer.onboarded") private var onboarded = false
    @AppStorage("coffer.haptics") private var haptics = true

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(Color(hex: 0x5A6B8C))
        .onAppear {
            Haptics.enabled = haptics
            SeedData.seedIfNeeded(context)
        }
        .onChange(of: onboarded) { _, _ in SeedData.seedIfNeeded(context) }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { OverviewView() }
                .tabItem { Label("Overview", systemImage: "chart.pie.fill") }
            NavigationStack { RoomsView() }
                .tabItem { Label("Rooms", systemImage: "square.split.bottomrightquarter") }
            NavigationStack { ItemsView() }
                .tabItem { Label("Items", systemImage: "shippingbox.fill") }
            NavigationStack { WarrantiesView() }
                .tabItem { Label("Warranties", systemImage: "checkmark.shield.fill") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
