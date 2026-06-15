import SwiftUI
import SwiftData

@main
struct ReveilleApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @StateObject private var settings = AppSettings()
    @StateObject private var ring = RingController()
    @StateObject private var notifications = NotificationManager()
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Alarm.self, WakeLog.self)
        } catch {
            // In-memory fallback keeps the app usable even if the on-disk store is unreadable.
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            do {
                container = try ModelContainer(for: Alarm.self, WakeLog.self, configurations: config)
            } catch {
                // Last-resort empty container; SwiftData guarantees at least one model type works.
                container = try! ModelContainer(for: Alarm.self)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(settings)
            .environmentObject(ring)
            .environmentObject(notifications)
            .tint(Theme.accent)
            .task { ring.configure(settings: settings) }
        }
        .modelContainer(container)
    }
}
