import SwiftUI
import SwiftData

struct BoardsListView: View {
    @Query(sort: \VisionBoard.sortOrder, order: .forward) private var boards: [VisionBoard]
    @Environment(\.modelContext) private var modelContext
    @State private var showCreate = false
    @State private var editBoard: VisionBoard? = nil

    var body: some View {
        Group {
            if boards.isEmpty {
                emptyState
            } else {
                boardGrid
            }
        }
        .navigationTitle("Boards")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showCreate = true } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create new vision board")
            }
        }
        .sheet(isPresented: $showCreate) {
            BoardEditView(board: nil)
        }
        .sheet(item: $editBoard) { b in
            BoardEditView(board: b)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Vision Boards Yet",
            systemImage: "photo.on.rectangle.angled",
            description: Text("Tap + to create your first vision board and start manifesting your dreams.")
        )
    }

    private var boardGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(boards) { board in
                    NavigationLink(destination: BoardDetailView(board: board)) {
                        BoardCardView(board: board)
                    }
                    .contextMenu {
                        Button("Edit Board") { editBoard = board }
                        Button("Delete Board", role: .destructive) { deleteBoard(board) }
                    }
                }
            }
            .padding(16)
        }
    }

    private func deleteBoard(_ board: VisionBoard) {
        board.items.forEach { item in
            if let fn = item.imageFilename { ImageStore.delete(fn) }
        }
        modelContext.delete(board)
    }
}
