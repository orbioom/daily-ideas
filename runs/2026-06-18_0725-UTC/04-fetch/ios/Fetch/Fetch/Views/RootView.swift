import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasSeeded") private var hasSeeded = false
    @Query private var dogs: [Dog]
    @State private var didPrepare = false

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }

            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }

            ProgramsView()
                .tabItem { Label("Programs", systemImage: "rectangle.stack.fill") }

            DogsView()
                .tabItem { Label("Dogs", systemImage: "pawprint.fill") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
        }
        .tint(Theme.accent)
        .task {
            guard !didPrepare else { return }
            didPrepare = true
            SeedData.seedIfNeeded(context: context, hasSeeded: &hasSeeded)
            DogManager.normalizeActive(dogs, context: context)
        }
    }
}
