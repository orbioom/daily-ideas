import SwiftUI

struct RootView: View {
    @State private var pro = ProStore()

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "checklist") }
            MedsView()
                .tabItem { Label("Meds", systemImage: "pills.fill") }
            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
            RefillsView()
                .tabItem { Label("Refills", systemImage: "shippingbox.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environment(pro)
        .tint(Theme.accent)
    }
}
