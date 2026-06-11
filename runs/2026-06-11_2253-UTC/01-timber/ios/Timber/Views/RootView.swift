import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("appearance") private var appearance = "system"
    @State private var recorder = RecorderEngine()

    var body: some View {
        TabView {
            TonightView()
                .tabItem { Label("Tonight", systemImage: "moon.zzz.fill") }
            JournalView()
                .tabItem { Label("Journal", systemImage: "book.closed.fill") }
            TrendsView()
                .tabItem { Label("Trends", systemImage: "chart.line.uptrend.xyaxis") }
            FactorsView()
                .tabItem { Label("Remedies", systemImage: "leaf.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.amber)
        .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
        .environment(recorder)
        .task { seedFactorsIfNeeded() }
    }

    private func seedFactorsIfNeeded() {
        let descriptor = FetchDescriptor<SleepFactor>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }
        for (name, emoji) in SleepFactor.builtIns {
            context.insert(SleepFactor(name: name, emoji: emoji, isBuiltIn: true))
        }
    }
}
