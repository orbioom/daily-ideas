import SwiftUI
import SwiftData

/// Root tab bar. Seeds realistic sample content on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeed") private var didSeed = false

    var body: some View {
        TabView {
            WalletScreen()
                .tabItem { Label("Wallet", systemImage: "wallet.pass.fill") }

            GiftCardsScreen()
                .tabItem { Label("Gift Cards", systemImage: "giftcard.fill") }

            InsightsScreen()
                .tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .task {
            if !didSeed {
                SeedData.insertSampleLoyaltyCards(context: context)
                SeedData.insertSampleGiftCards(context: context)
                didSeed = true
            }
        }
    }
}
