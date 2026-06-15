import SwiftUI
import SwiftData

/// Tab shell. Seeds sample data on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @State private var selection: Tab = .reading

    enum Tab: Hashable {
        case reading, archive, library, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            ReadingListView()
                .tabItem { Label("Read", systemImage: "books.vertical.fill") }
                .tag(Tab.reading)

            ArchiveView()
                .tabItem { Label("Archive", systemImage: "archivebox.fill") }
                .tag(Tab.archive)

            LibraryView()
                .tabItem { Label("Library", systemImage: "tag.fill") }
                .tag(Tab.library)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .task {
            Seeder.seedIfNeeded(context: context, wpm: settings.wordsPerMinute)
        }
    }
}
