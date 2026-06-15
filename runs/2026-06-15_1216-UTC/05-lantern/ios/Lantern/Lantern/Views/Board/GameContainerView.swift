import SwiftUI
import SwiftData

/// Resolves a `GameLaunch` into a configured `GameViewModel` and presents the
/// BoardView. Handles resuming a persisted SavedGame.
struct GameContainerView: View {
    let launch: GameLaunch
    @Environment(\.modelContext) private var modelContext
    @State private var resolved: GameViewModel?
    @State private var failed = false

    var body: some View {
        Group {
            if let vm = resolved {
                BoardView(viewModel: vm)
                    .id(ObjectIdentifier(vm))
            } else if failed {
                errorView
            } else {
                ProgressView().tint(Theme.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.bg.ignoresSafeArea())
            }
        }
        .onAppear { if resolved == nil { build() } }
    }

    private var errorView: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40)).foregroundStyle(Theme.warn)
            Text("Couldn't open that game")
                .font(Theme.serif(20, .semibold)).foregroundStyle(Theme.ink)
            Text("The saved board could not be read. Start a fresh board from the menu.")
                .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
    }

    private func build() {
        switch launch.source {
        case .fresh(let layout):
            let seed = UInt64.random(in: 1...UInt64.max)
            let vm = GameViewModel(layout: layout, seed: seed)
            resolved = vm

        case .daily(let dateKey, let layout):
            let seed = UInt64(stableSeed: dateKey + layout.rawValue)
            let vm = GameViewModel(layout: layout, seed: seed, isDaily: true, dailyDateKey: dateKey)
            resolved = vm

        case .resume:
            let descriptor = FetchDescriptor<SavedGame>(
                sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
            )
            guard let saved = try? modelContext.fetch(descriptor), let game = saved.first,
                  let state = SavedGameState.decode(from: game.stateData) else {
                failed = true
                return
            }
            let seed = state.dailyDateKey.map { UInt64(stableSeed: $0 + state.layout.rawValue) }
                ?? UInt64.random(in: 1...UInt64.max)
            let vm = GameViewModel(
                layout: state.layout,
                seed: seed,
                isDaily: state.isDaily,
                dailyDateKey: state.dailyDateKey
            )
            vm.restore(from: state)
            resolved = vm
        }
    }
}
