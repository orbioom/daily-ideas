import SwiftUI
import SwiftData

struct DailyTabView: View {
    @Environment(\.modelContext) private var context
    @Query private var games: [WordGame]
    @AppStorage("hardMode") private var hardMode = false

    @State private var vm: LexicGame?

    private var todayKey: String { WordEngine.dailyKey() }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 0) {
                    header
                    if let vm {
                        GameBoardView(vm: vm, onNewGame: nil)
                            .id(vm.game.id)
                    } else {
                        Spacer()
                        ProgressView().tint(Brand.text)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Daily #\(StatsEngine.dayNumber())")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear(perform: loadDaily)
    }

    private var header: some View {
        HStack {
            Text(Date.now, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                .font(.subheadline).foregroundStyle(Brand.text2)
            Spacer()
            if hardMode {
                Label("Hard", systemImage: "flame.fill")
                    .font(.caption).foregroundStyle(Brand.danger)
            }
        }
        .padding(.horizontal, 20).padding(.top, 4)
    }

    private func loadDaily() {
        guard vm == nil else { return }
        let key = todayKey
        if let existing = games.first(where: { $0.mode == .daily && $0.dailyKey == key }) {
            vm = LexicGame(game: existing, context: context)
        } else {
            let game = WordGame(answer: WordEngine.dailyAnswer(), mode: .daily,
                                hardMode: hardMode, dailyKey: key)
            context.insert(game)
            try? context.save()
            vm = LexicGame(game: game, context: context)
        }
    }
}

#Preview {
    DailyTabView().modelContainer(for: WordGame.self, inMemory: true)
}
