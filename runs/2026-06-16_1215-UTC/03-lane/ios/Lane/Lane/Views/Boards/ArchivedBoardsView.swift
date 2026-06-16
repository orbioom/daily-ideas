import SwiftUI
import SwiftData

struct ArchivedBoardsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: \Board.sortIndex, order: .forward)
    private var allBoards: [Board]

    private var archived: [Board] { allBoards.filter { $0.isArchived } }

    var body: some View {
        NavigationStack {
            Group {
                if archived.isEmpty {
                    EmptyStateView(
                        symbol: "archivebox",
                        title: "Nothing archived",
                        message: "Boards you archive will appear here. You can restore them any time."
                    )
                } else {
                    List {
                        ForEach(archived) { board in
                            HStack(spacing: 12) {
                                Image(systemName: board.symbolName)
                                    .foregroundStyle(Color(hex: UInt(max(0, board.colorHex))))
                                Text(board.name)
                                    .font(Theme.rounded(16, .semibold))
                                Spacer()
                                Button("Restore") { restore(board) }
                                    .font(Theme.rounded(14, .semibold))
                                    .buttonStyle(.borderless)
                            }
                            .swipeActions {
                                Button(role: .destructive) { delete(board) } label: {
                                    SwiftUI.Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Archived")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func restore(_ board: Board) {
        board.isArchived = false
        let maxIndex = allBoards.filter { !$0.isArchived }.map(\.sortIndex).max() ?? -1
        board.sortIndex = maxIndex + 1
        try? context.save()
        Haptics.impact(.light, enabled: settings.hapticsEnabled)
    }

    private func delete(_ board: Board) {
        context.delete(board)
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
    }
}
