import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("ledger.hasOnboarded") private var hasOnboarded = false
    @AppStorage("ledger.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("ledger.appearance") private var appearance = "system"
    @Query private var accounts: [Account]

    private var scheme: ColorScheme? {
        switch appearance { case "light": return .light; case "dark": return .dark; default: return nil }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            if hasOnboarded {
                TabView {
                    AccountsView()
                        .tabItem { Label("Accounts", systemImage: "wallet.pass") }
                    HistoryView()
                        .tabItem { Label("History", systemImage: "chart.xyaxis.line") }
                    AllocationView()
                        .tabItem { Label("Allocation", systemImage: "chart.pie") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                }
                .tint(Brand.text)
            } else {
                OnboardingView {
                    if accounts.isEmpty { SampleData.seed(into: context) }
                    hasOnboarded = true
                }
            }
        }
        .preferredColorScheme(scheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
    }
}
