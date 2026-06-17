import SwiftUI
import SwiftData

/// Tabs available in Sigma.
enum SigmaTab: Hashable {
    case calculator, history, converter, programmer
}

/// The root tab container. Owns the shared `CalculatorModel` and seeds sample data once.
struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Environment(\.modelContext) private var context

    @State private var calculator = CalculatorModel()
    @State private var selectedTab: SigmaTab = .calculator
    @State private var didSeed = false

    var body: some View {
        TabView(selection: $selectedTab) {
            CalculatorView(calculator: calculator)
                .tabItem { Label("Calc", systemImage: "function") }
                .tag(SigmaTab.calculator)

            HistoryView(calculator: calculator, selectedTab: $selectedTab)
                .tabItem { Label("History", systemImage: "list.bullet.rectangle") }
                .tag(SigmaTab.history)

            ConverterView()
                .tabItem { Label("Convert", systemImage: "arrow.left.arrow.right") }
                .tag(SigmaTab.converter)

            ProgrammerView()
                .tabItem { Label("Base", systemImage: "number.square") }
                .tag(SigmaTab.programmer)
        }
        .tint(settings.activeTheme(isPro: pro.isPro).accent)
        .task {
            // Brief async seeding pass with a guard so it only runs once.
            guard !didSeed else { return }
            didSeed = true
            calculator.angle = settings.defaultAngle
            SeedData.seedIfNeeded(context: context)
        }
    }
}
