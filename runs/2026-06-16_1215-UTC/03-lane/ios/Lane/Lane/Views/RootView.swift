import SwiftUI

struct RootView: View {
    @State private var selection: Tab = .boards

    enum Tab: Hashable {
        case boards, agenda, insights, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            BoardsView()
                .tabItem { SwiftUI.Label("Boards", systemImage: "square.stack.3d.up.fill") }
                .tag(Tab.boards)

            AgendaView()
                .tabItem { SwiftUI.Label("Agenda", systemImage: "calendar") }
                .tag(Tab.agenda)

            InsightsView()
                .tabItem { SwiftUI.Label("Insights", systemImage: "chart.bar.xaxis") }
                .tag(Tab.insights)

            SettingsView()
                .tabItem { SwiftUI.Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(Theme.accent)
    }
}
