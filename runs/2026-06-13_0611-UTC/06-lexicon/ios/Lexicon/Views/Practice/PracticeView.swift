import SwiftUI
import SwiftData

struct PracticeView: View {
    @Environment(\.modelContext) private var context
    @State private var vm = PracticeView.make()
    @State private var configured = false

    private static func make() -> GameViewModel {
        GameViewModel(answer: WordGame.randomAnswer(), dayKey: "",
                      hardMode: UserDefaults.standard.bool(forKey: "hardMode"),
                      persistProgress: false)
    }

    var body: some View {
        NavigationStack {
            GameView(vm: vm, title: "Practice", resultPrimaryLabel: "New word",
                     onResultPrimary: { newGame() })
                .id(ObjectIdentifier(vm))
                .navigationTitle("Practice")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { newGame() } label: { Image(systemName: "arrow.clockwise") }
                            .accessibilityLabel("New word")
                    }
                }
        }
        .onAppear { configure() }
    }

    private func configure() {
        vm.onComplete = { [weak vm] won, guesses in
            guard let vm else { return }
            GameRecords.record(context, dayKey: "", answer: vm.answer,
                               guesses: guesses, won: won, hardMode: vm.hardMode)
        }
        configured = true
    }

    private func newGame() {
        vm = PracticeView.make()
        configure()
    }
}
