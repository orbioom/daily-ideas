import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @State private var didSeed = false
    @State private var isSeeding = false
    @State private var selection: Tab = .pipeline

    enum Tab: Hashable {
        case pipeline, upcoming, insights, settings
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            if isSeeding {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(Theme.accent)
                    Text("Setting up your pipeline…")
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Setting up your pipeline")
            } else {
                TabView(selection: $selection) {
                    PipelineView()
                        .tabItem { Label("Pipeline", systemImage: "list.bullet.rectangle.portrait") }
                        .tag(Tab.pipeline)

                    UpcomingView()
                        .tabItem { Label("Upcoming", systemImage: "calendar") }
                        .tag(Tab.upcoming)

                    InsightsView()
                        .tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }
                        .tag(Tab.insights)

                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                        .tag(Tab.settings)
                }
                .tint(Theme.accent)
            }
        }
        .task {
            guard !didSeed else { return }
            didSeed = true
            isSeeding = true
            // Seeding is fast but we surface a brief loading state per the design system.
            SeedData.seedIfNeeded(context: context)
            try? context.save()
            try? await Task.sleep(nanoseconds: 250_000_000)
            isSeeding = false
        }
    }
}
