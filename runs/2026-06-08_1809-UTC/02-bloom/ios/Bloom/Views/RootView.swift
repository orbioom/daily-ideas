import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var pregnancies: [Pregnancy]
    @AppStorage("bloom.haptics") private var haptics = true

    var body: some View {
        ZStack {
            Brand.pageBackground
            if let pregnancy = pregnancies.first {
                MainTabView(pregnancy: pregnancy)
            } else {
                OnboardingView()
            }
        }
        .tint(Color(hex: 0x9A6FB0))
        .onAppear { Haptics.enabled = haptics }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
    }
}

struct MainTabView: View {
    let pregnancy: Pregnancy

    var body: some View {
        TabView {
            OverviewView(pregnancy: pregnancy)
                .tabItem { Label("Today", systemImage: "heart.circle") }
            WeeksView(pregnancy: pregnancy)
                .tabItem { Label("Weeks", systemImage: "calendar") }
            CareView(pregnancy: pregnancy)
                .tabItem { Label("Care", systemImage: "cross.case") }
            ToolsView()
                .tabItem { Label("Tools", systemImage: "stopwatch") }
        }
    }
}
