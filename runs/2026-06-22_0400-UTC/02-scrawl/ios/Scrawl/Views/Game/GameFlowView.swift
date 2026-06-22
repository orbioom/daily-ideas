import SwiftUI

struct GameFlowView: View {
    @Bindable var engine: ScrawlGameEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch engine.phase {
            case .setup:
                // Should not normally show - handled by SetupView
                Text("Setting up...")
                    .onAppear { dismiss() }
            case .wordReveal:
                WordRevealView(engine: engine)
            case .drawing:
                DrawPhaseView(engine: engine)
            case .guessing:
                GuessPhaseView(engine: engine)
            case .result:
                ResultView(engine: engine)
            case .gameOver:
                GameOverView(engine: engine)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: engine.phase)
    }
}
