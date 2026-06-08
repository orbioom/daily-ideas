import SwiftUI
import SwiftData

struct RootView: View {
    @Query(sort: \Vehicle.createdAt) private var vehicles: [Vehicle]
    @AppStorage("axle.haptics") private var haptics = true

    var body: some View {
        ZStack {
            Brand.pageBackground
            if vehicles.isEmpty {
                OnboardingView()
            } else {
                MainTabView(vehicles: vehicles)
            }
        }
        .tint(Color(hex: 0x4E6BA8))
        .onAppear { Haptics.enabled = haptics }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
    }
}

struct MainTabView: View {
    let vehicles: [Vehicle]
    @State private var selectedID: PersistentIdentifier?

    private var selected: Vehicle {
        vehicles.first { $0.persistentModelID == selectedID } ?? vehicles[0]
    }

    var body: some View {
        TabView {
            DashboardView(vehicle: selected, vehicles: vehicles, selectedID: $selectedID)
                .tabItem { Label("Dashboard", systemImage: "gauge.with.dots.needle.50percent") }
            FuelView(vehicle: selected)
                .tabItem { Label("Fuel", systemImage: "fuelpump") }
            ServiceView(vehicle: selected)
                .tabItem { Label("Service", systemImage: "wrench.and.screwdriver") }
            RemindersView(vehicle: selected)
                .tabItem { Label("Reminders", systemImage: "bell.badge") }
        }
        .onAppear {
            if selectedID == nil { selectedID = vehicles.first?.persistentModelID }
        }
    }
}
