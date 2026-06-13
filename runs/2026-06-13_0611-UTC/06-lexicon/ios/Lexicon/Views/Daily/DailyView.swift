import SwiftUI
import SwiftData

struct DailyView: View {
    @Environment(\.modelContext) private var context
    @State private var vm = GameViewModel(
        answer: WordGame.dailyAnswer(),
        dayKey: WordGame.dayKey(),
        hardMode: UserDefaults.standard.bool(forKey: "hardMode"),
        persistProgress: true)
    @State private var configured = false

    var body: some View {
        NavigationStack {
            GameView(vm: vm, title: WordGame.dayKey(), resultPrimaryLabel: "Done")
                .navigationTitle("Daily")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 0) {
                            Text("Daily").font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.ink)
                            Text(Date.now, format: .dateTime.weekday(.wide).month().day())
                                .font(.system(size: 11)).foregroundStyle(Theme.inkFaint)
                        }
                    }
                }
        }
        .onAppear {
            guard !configured else { return }
            configured = true
            vm.onComplete = { [weak vm] won, guesses in
                guard let vm else { return }
                GameRecords.record(context, dayKey: vm.dayKey, answer: vm.answer,
                                   guesses: guesses, won: won, hardMode: vm.hardMode)
            }
        }
    }
}
