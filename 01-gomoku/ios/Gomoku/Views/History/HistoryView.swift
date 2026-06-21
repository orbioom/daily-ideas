import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \GomokuResult.date, order: .reverse) private var results: [GomokuResult]
    @Environment(\.modelContext) private var ctx

    var body: some View {
        NavigationStack {
            Group {
                if results.isEmpty {
                    ContentUnavailableView("No Games Yet",
                        systemImage: "clock.badge.xmark",
                        description: Text("Finish a game on the Play tab to see your history here."))
                } else {
                    List {
                        ForEach(results) { r in
                            HStack(spacing: 14) {
                                outcomeIcon(r.outcome)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(outcomeLabel(r.outcome))
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(r.difficulty) · \(r.moves) moves · \(r.durationSeconds)s")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(r.date, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.map { results[$0] }.forEach { ctx.delete($0) }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !results.isEmpty {
                    EditButton()
                }
            }
        }
        .accessibilityLabel("Game history")
    }

    private func outcomeIcon(_ outcome: String) -> some View {
        let (icon, color): (String, Color) = switch outcome {
        case "win": ("trophy.fill", .yellow)
        case "loss": ("xmark.circle.fill", .red)
        default: ("equal.circle.fill", .orange)
        }
        return Image(systemName: icon)
            .font(.title3)
            .foregroundStyle(color)
            .frame(width: 32)
    }

    private func outcomeLabel(_ outcome: String) -> String {
        switch outcome {
        case "win": return "You Won"
        case "loss": return "AI Won"
        default: return "Draw"
        }
    }
}
