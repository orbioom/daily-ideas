import SwiftUI
import SwiftData

/// The primary tabbed experience: Convert, Scale, Substitute, Timers, Reference.
/// Settings is reachable from a toolbar gear on each root screen.
struct MainTabView: View {
    @Environment(\.colorScheme) private var scheme

    /// One shared TimerEngine drives the live timers + completion alerts.
    @State private var timerEngine = TimerEngine()
    @State private var selection: Tab = .convert

    enum Tab: Hashable { case convert, scale, substitute, timers, reference }

    var body: some View {
        TabView(selection: $selection) {
            ConvertView()
                .tabItem { Label("Convert", systemImage: "arrow.left.arrow.right") }
                .tag(Tab.convert)

            ScaleView()
                .tabItem { Label("Scale", systemImage: "slider.horizontal.3") }
                .tag(Tab.scale)

            SubstituteView()
                .tabItem { Label("Sub", systemImage: "arrow.triangle.2.circlepath") }
                .tag(Tab.substitute)

            TimersView()
                .environment(timerEngine)
                .tabItem { Label("Timers", systemImage: "timer") }
                .tag(Tab.timers)

            ReferenceView()
                .tabItem { Label("Reference", systemImage: "book") }
                .tag(Tab.reference)
        }
        .tint(GalleyTheme.terracotta)
    }
}
