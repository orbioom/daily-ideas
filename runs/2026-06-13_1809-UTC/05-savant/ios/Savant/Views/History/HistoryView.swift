import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \GameResult.date, order: .reverse) private var results: [GameResult]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if results.isEmpty {
                    EmptyStateView(icon: "clock.arrow.circlepath",
                                   title: "No games yet",
                                   message: "Every round you play is logged here, with your score and accuracy.")
                } else {
                    List {
                        ForEach(results) { r in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(r.mode == .daily ? Theme.gold.opacity(0.18) : Theme.accentSoft)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: r.mode == .daily ? "bolt.fill" : (r.category?.icon ?? "square.grid.2x2.fill"))
                                        .foregroundStyle(r.mode == .daily ? Theme.gold : Theme.accent)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.mode == .daily ? "Daily Challenge" : (r.category?.label ?? "Mixed practice"))
                                        .font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                                    Text("\(Fmt.relativeDay(r.date)) · \(r.correct)/\(r.total) correct")
                                        .font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkSoft)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 1) {
                                    Text("\(r.score)").font(Theme.rounded(18, .bold)).foregroundStyle(Theme.accent)
                                    Text("pts").font(Theme.rounded(10, .medium)).foregroundStyle(Theme.inkSoft)
                                }
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Theme.surface)
                        }
                        .onDelete(perform: delete)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
        }
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { context.delete(results[i]) }
        try? context.save()
    }
}
