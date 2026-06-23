import SwiftUI
import SwiftData

/// Root tab interface. Resolves the active baby and shares it down to each tab.
struct MainTabView: View {
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \Baby.createdAt) private var babies: [Baby]
    @AppStorage(PrefKey.activeBabyID) private var activeBabyIDString = ""

    /// The currently selected baby, defaulting to the first available.
    private var activeBaby: Baby? {
        if let id = UUID(uuidString: activeBabyIDString),
           let match = babies.first(where: { $0.id == id }) {
            return match
        }
        return babies.first
    }

    var body: some View {
        TabView {
            tab(content: { baby in TodayView(baby: baby) },
                empty: "Today",
                title: "Today", systemImage: "sun.max.fill")

            tab(content: { baby in LogTimelineView(baby: baby) },
                empty: "Timeline",
                title: "Timeline", systemImage: "list.bullet.rectangle")

            tab(content: { baby in TrendsView(baby: baby) },
                empty: "Trends",
                title: "Trends", systemImage: "chart.bar.fill")

            tab(content: { baby in GrowthView(baby: baby) },
                empty: "Growth",
                title: "Growth", systemImage: "ruler.fill")

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.accent)
    }

    /// Wraps a feature tab, supplying the active baby or an onboarding-style
    /// empty state if every profile was somehow removed.
    @ViewBuilder
    private func tab<Content: View>(
        @ViewBuilder content: @escaping (Baby) -> Content,
        empty: String,
        title: String,
        systemImage: String
    ) -> some View {
        Group {
            if let baby = activeBaby {
                content(baby)
            } else {
                NoBabyView()
            }
        }
        .tabItem { Label(title, systemImage: systemImage) }
    }
}

/// Shown only in the unlikely event that all babies were deleted.
struct NoBabyView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ambientGradient(scheme).ignoresSafeArea()
                EmptyStateView(
                    systemImage: "leaf.fill",
                    title: "No baby yet",
                    message: "Add a baby profile to start logging feeds, sleep, diapers and growth.",
                    actionTitle: "Add a baby",
                    action: { showAdd = true }
                )
            }
            .navigationTitle("Sprig")
            .sheet(isPresented: $showAdd) {
                BabyEditorView(baby: nil)
            }
        }
    }
}
