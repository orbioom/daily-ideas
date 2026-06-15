import SwiftUI
import SwiftData

/// Root tab bar. Seeds sample alarms + WakeLogs on first appearance, syncs notification
/// backstops, and presents the full-screen Ring takeover whenever an alarm is firing.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var ring: RingController
    @EnvironmentObject private var notifications: NotificationManager
    @AppStorage("didSeed") private var didSeed = false

    @Query private var alarms: [Alarm]

    var body: some View {
        TabView {
            AlarmsScreen()
                .tabItem { Label("Alarms", systemImage: "alarm.fill") }

            BedsideScreen()
                .tabItem { Label("Bedside", systemImage: "moon.stars.fill") }

            StatsScreen()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .task {
            var seeded = didSeed
            SeedData.seedIfNeeded(context: context, didSeed: &seeded)
            didSeed = seeded
            await notifications.refresh()
            notifications.resyncAll(alarms)
        }
        .fullScreenCover(isPresented: Binding(
            get: { ring.isRinging },
            set: { presented in if !presented { ring.cancel() } }
        )) {
            RingScreen()
        }
    }
}
