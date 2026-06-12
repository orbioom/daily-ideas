import SwiftUI
import SwiftData

@main
struct PalaceApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("drawThree") private var drawThree = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var engine: GameEngine

    init() {
        if let saved = GameStore.load() {
            _engine = State(initialValue: GameEngine(state: saved))
        } else {
            let drawThree = UserDefaults.standard.bool(forKey: "drawThree")
            _engine = State(initialValue: GameEngine(drawThree: drawThree))
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootTabView()
                } else {
                    OnboardingView()
                }
            }
            .environment(engine)
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .background, .inactive:
                    engine.pauseClock()
                    if engine.isWon {
                        GameStore.clear()
                    } else {
                        GameStore.save(engine.state)
                    }
                default:
                    break
                }
            }
        }
        .modelContainer(for: GameRecord.self)
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            GameView()
                .tabItem { Label("Play", systemImage: "suit.spade.fill") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            LearnView()
                .tabItem { Label("Learn", systemImage: "book.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
