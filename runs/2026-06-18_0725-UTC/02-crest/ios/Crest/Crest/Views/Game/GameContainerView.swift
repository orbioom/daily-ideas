import SwiftUI
import SwiftData

/// Owns the GameViewModel, wires scenePhase to the wall-clock timer, persists
/// the saved game, and records the result on finish.
struct GameContainerView: View {
    let request: GameRequest
    /// Called when the user wants to exit to Home (pops the stack).
    let onExit: () -> Void

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    @State private var vm: GameViewModel?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let vm {
                GameBoardScreen(vm: vm, onExit: exit, onRestart: restart)
            } else if loadFailed {
                loadError
            } else {
                loading
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await load() }
        .onChange(of: scenePhase) { _, phase in
            handleScenePhase(phase)
        }
    }

    private var loading: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView().tint(Theme.accent)
                Text("Dealing the cards…")
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private var loadError: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Couldn't load that game",
                    message: "The saved board may be from an older version. Start a fresh deal instead."
                )
                PrimaryButton(title: "Back to Home", icon: "house.fill") { onExit() }
                    .padding(.horizontal, 40)
            }
        }
    }

    private func load() async {
        // Brief async hop so the dealing spinner is visible and the heavy deal
        // doesn't block the first frame.
        try? await Task.sleep(nanoseconds: 220_000_000)

        if request.resume {
            let descriptor = FetchDescriptor<SavedGame>(predicate: #Predicate { $0.slot == 0 })
            if let saved = (try? context.fetch(descriptor))?.first,
               let st = saved.decodedState() {
                vm = GameViewModel(resuming: st,
                                   startedAt: saved.startedAt,
                                   elapsedAccum: saved.elapsedAccum,
                                   wrap: settings.wrapAround)
                return
            }
            loadFailed = true
            return
        }

        vm = GameViewModel(layout: request.layout,
                           dealNumber: request.dealNumber,
                           isDaily: request.isDaily,
                           wrap: settings.wrapAround)
        vm?.persist(into: context)
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        guard let vm else { return }
        switch phase {
        case .active:
            vm.resumeClock()
        case .inactive, .background:
            vm.pauseClock()
            vm.persist(into: context)
        @unknown default:
            break
        }
    }

    private func exit() {
        if let vm {
            vm.pauseClock()
            vm.persist(into: context)
        }
        onExit()
    }

    private func restart() {
        guard let old = vm else { return }
        old.clearSaved(in: context)
        let fresh = GameViewModel(layout: request.layout,
                                  dealNumber: request.dealNumber,
                                  isDaily: request.isDaily,
                                  wrap: settings.wrapAround)
        fresh.persist(into: context)
        vm = fresh
    }
}
