import SwiftUI

struct ContentView: View {
    @AppStorage("brief_selected_tab") private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            InvoiceListView()
                .tabItem { Label("Invoices", systemImage: "doc.text.fill") }
                .tag(0)
            ClientListView()
                .tabItem { Label("Clients", systemImage: "person.2.fill") }
                .tag(1)
            BriefSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .tint(BriefTheme.accent)
    }
}
