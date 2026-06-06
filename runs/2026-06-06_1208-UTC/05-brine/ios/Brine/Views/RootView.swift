import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Tank.createdAt) private var tanks: [Tank]
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("didSeed") private var didSeed = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("selectedTankID") private var selectedTankID = ""

    @State private var creatingTank: Tank?

    private var activeTank: Tank? {
        tanks.first { $0.id.uuidString == selectedTankID } ?? tanks.first
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            if !hasOnboarded {
                OnboardingView { hasOnboarded = true }.transition(.opacity)
            } else if let tank = activeTank {
                MainTabs(tank: tank, tanks: tanks, selectedTankID: $selectedTankID,
                         onAddTank: { addTank() })
            } else {
                noTankState
            }
        }
        .animation(Brand.ease(), value: hasOnboarded)
        .task {
            Haptics.enabled = hapticsEnabled
            if !didSeed { SampleData.seed(into: context); didSeed = true }
        }
        .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
        .sheet(item: $creatingTank) { TankEditView(tank: $0, isNew: true) {
            selectedTankID = $0.id.uuidString
        } }
    }

    private var noTankState: some View {
        VStack(spacing: 20) {
            EmptyStateView(icon: "drop", title: "No tanks yet",
                           message: "Add your first aquarium to start tracking its water.")
            Button("Add a tank") { addTank() }
                .buttonStyle(InkButtonStyle()).padding(.horizontal, 40)
        }
    }

    private func addTank() {
        let t = Tank(name: "")
        context.insert(t)
        creatingTank = t
        Haptics.tap()
    }
}

/// The five-tab interface bound to the active tank.
struct MainTabs: View {
    let tank: Tank
    let tanks: [Tank]
    @Binding var selectedTankID: String
    var onAddTank: () -> Void

    var body: some View {
        TabView {
            DashboardView(tank: tank, tanks: tanks, selectedTankID: $selectedTankID, onAddTank: onAddTank)
                .tabItem { Label("Dashboard", systemImage: "gauge.with.dots.needle.bottom.50percent") }
            ParametersView(tank: tank)
                .tabItem { Label("Parameters", systemImage: "drop.degreesign") }
            DosingView(tank: tank)
                .tabItem { Label("Dosing", systemImage: "eyedropper") }
            TasksView(tank: tank)
                .tabItem { Label("Care", systemImage: "checklist") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Brand.text)
    }
}
