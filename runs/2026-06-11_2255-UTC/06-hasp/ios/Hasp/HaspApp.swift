import SwiftUI

@main
struct HaspApp: App {
    @State private var store = VaultStore()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("autoLockMinutes") private var autoLockMinutes = 1
    @AppStorage("lastBackgroundedAt") private var lastBackgroundedAt = 0.0

    var body: some Scene {
        WindowGroup {
            Group {
                switch store.state {
                case .noVault:
                    OnboardingView(store: store)
                case .locked:
                    LockView(store: store)
                case .unlocked:
                    VaultRootView(store: store)
                }
            }
            .tint(Theme.accent)
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .background:
                    lastBackgroundedAt = Date.now.timeIntervalSince1970
                case .active:
                    guard store.state == .unlocked, lastBackgroundedAt > 0 else { return }
                    let away = Date.now.timeIntervalSince1970 - lastBackgroundedAt
                    if autoLockMinutes == 0 || away >= Double(autoLockMinutes) * 60 {
                        store.lock()
                    }
                default:
                    break
                }
            }
        }
    }
}

struct VaultRootView: View {
    @Bindable var store: VaultStore

    var body: some View {
        TabView {
            VaultListView(store: store)
                .tabItem { Label("Vault", systemImage: "lock.shield") }
            GeneratorView(store: store)
                .tabItem { Label("Generator", systemImage: "dice") }
            SettingsView(store: store)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
