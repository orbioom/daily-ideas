import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Query private var records: [GameRecord]

    private let backDays = 90

    private var recordByKey: [String: GameRecord] {
        Dictionary(records.filter { $0.isDaily }.map { ($0.dayKey, $0) }, uniquingKeysWith: { a, _ in a })
    }

    private var days: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<backDays).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                List {
                    Section {
                        ForEach(days, id: \.self) { day in
                            NavigationLink(value: WordGame.dayKey(day)) {
                                archiveRow(day)
                            }
                            .listRowBackground(Theme.surface)
                        }
                    } footer: {
                        Text("Every past daily puzzle, free to play. No ads, ever.")
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Archive")
            .navigationDestination(for: String.self) { key in
                ArchiveGameView(dayKey: key)
            }
        }
    }

    private func archiveRow(_ day: Date) -> some View {
        let key = WordGame.dayKey(day)
        let record = recordByKey[key]
        let isToday = Calendar.current.isDateInToday(day)
        return HStack(spacing: 12) {
            statusIcon(record)
            VStack(alignment: .leading, spacing: 2) {
                Text(day, format: .dateTime.weekday(.wide).month().day())
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                Text(statusText(record, isToday: isToday))
                    .font(.system(size: 12)).foregroundStyle(Theme.inkFaint)
            }
            Spacer()
            if let record, record.won {
                Text("\(record.attempts)/\(WordGame.maxRows)")
                    .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Theme.correct)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(day.formatted(.dateTime.month().day())), \(statusText(record, isToday: isToday))")
    }

    private func statusIcon(_ record: GameRecord?) -> some View {
        let (name, color): (String, Color) = {
            guard let record else { return ("circle", Theme.inkFaint) }
            return record.won ? ("checkmark.circle.fill", Theme.correct) : ("xmark.circle.fill", Theme.absent)
        }()
        return Image(systemName: name).font(.system(size: 22)).foregroundStyle(color)
    }

    private func statusText(_ record: GameRecord?, isToday: Bool) -> String {
        if let record { return record.won ? "Solved" : "Missed — the word was \(record.answer.uppercased())" }
        return isToday ? "Today — not finished" : "Not played"
    }
}

struct ArchiveGameView: View {
    let dayKey: String
    @Environment(\.modelContext) private var context
    @State private var vm: GameViewModel
    @State private var configured = false

    init(dayKey: String) {
        self.dayKey = dayKey
        let date = WordGame.date(fromDayKey: dayKey) ?? .now
        _vm = State(initialValue: GameViewModel(
            answer: WordGame.dailyAnswer(for: date),
            dayKey: dayKey,
            hardMode: UserDefaults.standard.bool(forKey: "hardMode"),
            persistProgress: true))
    }

    var body: some View {
        GameView(vm: vm, title: dayKey, resultPrimaryLabel: "Done")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
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

    private var title: String {
        (WordGame.date(fromDayKey: dayKey) ?? .now).formatted(.dateTime.month().day().year())
    }
}
