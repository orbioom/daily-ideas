import SwiftUI
import SwiftData

/// App root: privacy onboarding gate, then the main tab experience. The "Add"
/// flow is reachable from anywhere via a prominent center tab and a shared sheet.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("contour.onboarded") private var onboarded = false
    @AppStorage("contour.haptics") private var haptics = true

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(Brand.magic)
        .onAppear {
            Haptics.enabled = haptics
            SeedData.seedIfNeeded(context)
        }
        .onChange(of: onboarded) { _, _ in SeedData.seedIfNeeded(context) }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
    }
}

/// Tab identifiers; `add` is intercepted to present the Add sheet instead of a page.
enum AppTab: Hashable {
    case timeline, compare, add, progress, settings
}

struct MainTabView: View {
    @State private var selection: AppTab = .timeline
    @State private var lastRealTab: AppTab = .timeline
    @State private var showAdd = false

    var body: some View {
        TabView(selection: $selection) {
            TimelineView(showAdd: $showAdd)
                .tabItem { Label("Timeline", systemImage: "square.grid.2x2") }
                .tag(AppTab.timeline)

            CompareView()
                .tabItem { Label("Compare", systemImage: "rectangle.split.2x1") }
                .tag(AppTab.compare)

            // Prominent center "Add" — tapping flips the sheet, never navigates.
            Color.clear
                .tabItem { Label("Add", systemImage: "plus.circle.fill") }
                .tag(AppTab.add)

            ProgressTabView()
                .tabItem { Label("Progress", systemImage: "chart.xyaxis.line") }
                .tag(AppTab.progress)

            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .onChange(of: selection) { _, new in
            if new == .add {
                showAdd = true
                // Bounce back to the previously selected real tab.
                selection = lastRealTab
                Haptics.tap()
            } else {
                lastRealTab = new
            }
        }
        .sheet(isPresented: $showAdd) {
            AddEntryView()
        }
    }
}
