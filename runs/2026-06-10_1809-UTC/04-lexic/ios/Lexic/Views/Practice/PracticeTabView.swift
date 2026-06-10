import SwiftUI
import SwiftData

struct PracticeTabView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WordGame.startedAt, order: .reverse) private var games: [WordGame]
    @AppStorage("hardMode") private var hardMode = false

    @State private var vm: LexicGame?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 0) {
                    header
                    if let vm {
                        GameBoardView(vm: vm, onNewGame: { newGame() })
                            .id(vm.game.id)
                    } else {
                        Spacer()
                        ProgressView().tint(Brand.text)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { newGame() } label: { Image(systemName: "arrow.clockwise") }
                        .accessibilityLabel("New word")
                }
            }
        }
        .onAppear(perform: load)
    }

    private var header: some View {
        HStack {
            Text("Unlimited words").font(.subheadline).foregroundStyle(Brand.text2)
            Spacer()
            if hardMode {
                Label("Hard", systemImage: "flame.fill").font(.caption).foregroundStyle(Brand.danger)
            }
        }
        .padding(.horizontal, 20).padding(.top, 4)
    }

    private func load() {
        guard vm == nil else { return }
        if let ongoing = games.first(where: { $0.mode == .unlimited && !$0.isFinished }) {
            vm = LexicGame(game: ongoing, context: context)
        } else {
            createGame()
        }
    }

    private func newGame() {
        createGame()
        Haptics.tap()
    }

    private func createGame() {
        let game = WordGame(answer: WordEngine.randomAnswer(), mode: .unlimited, hardMode: hardMode)
        context.insert(game)
        try? context.save()
        vm = LexicGame(game: game, context: context)
    }
}

#Preview {
    PracticeTabView().modelContainer(for: WordGame.self, inMemory: true)
}
