import SwiftUI

struct RootView: View {
    @AppStorage("appearance") private var appearance = "system"

    var body: some View {
        TabView {
            InventoryView()
                .tabItem { Label("Inventory", systemImage: "shippingbox.fill") }
            SalesView()
                .tabItem { Label("Sales", systemImage: "dollarsign.circle.fill") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.pie.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.tangerine)
        .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
    }
}

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("shippingbox.fill", "Know your real numbers",
         "Every flip tracked from thrift-store find to sold: cost, fees, shipping, and the profit that's actually yours. No spreadsheet, no $30/month web suite."),
        ("tag.fill", "Beat the death pile",
         "Flipside shows what you've sourced but never listed, and which listings have gone stale — so inventory turns into cash instead of closet filler."),
        ("chart.pie.fill", "Sell smarter",
         "ROI by item, profit by platform, average days to sell, sell-through rate. Find out where your hustle actually earns."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    VStack(spacing: 20) {
                        Image(systemName: pages[i].icon)
                            .font(.system(size: 60))
                            .foregroundStyle(Theme.tangerine)
                            .accessibilityHidden(true)
                        Text(pages[i].title)
                            .font(Theme.display(28))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.ink(scheme))
                        Text(pages[i].body)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.inkSoft(scheme))
                            .padding(.horizontal, 28)
                    }
                    .tag(i)
                    .padding(.bottom, 40)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < pages.count - 1 {
                    if reduceMotion { page += 1 }
                    else { withAnimation { page += 1 } }
                } else {
                    Haptics.success()
                    hasOnboarded = true
                }
            } label: {
                Text(page < pages.count - 1 ? "Continue" : "Start flipping")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.tangerine)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .background(Theme.background(scheme))
    }
}
