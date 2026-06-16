import SwiftUI
import SwiftData

struct BoardsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var proStore: ProStore

    @Query(sort: \Board.sortIndex, order: .forward)
    private var allBoards: [Board]

    @State private var showCreate = false
    @State private var showPaywall = false
    @State private var showArchived = false
    @State private var pendingDelete: Board?
    @State private var toast: ToastMessage?

    private var activeBoards: [Board] { allBoards.filter { !$0.isArchived } }
    private var archivedBoards: [Board] { allBoards.filter { $0.isArchived } }

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
    }

    var body: some View {
        NavigationStack {
            Group {
                if activeBoards.isEmpty {
                    EmptyStateView(
                        symbol: "square.stack.3d.up",
                        title: "No boards yet",
                        message: "Create your first board to start moving work across columns.",
                        actionTitle: "New Board",
                        action: { startCreate() }
                    )
                } else {
                    boardGrid
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Boards")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { startCreate() } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New board")
                }
                if !archivedBoards.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { showArchived = true } label: {
                            Image(systemName: "archivebox")
                        }
                        .accessibilityLabel("Archived boards")
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateBoardView { name, color, symbol, template in
                    createBoard(name: name, color: color, symbol: symbol, template: template)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showArchived) {
                ArchivedBoardsView()
            }
            .alert("Delete board?", isPresented: deleteAlertBinding) {
                Button("Cancel", role: .cancel) { pendingDelete = nil }
                Button("Delete", role: .destructive) { confirmDelete() }
            } message: {
                Text("This permanently deletes \"\(pendingDelete?.name ?? "")\" and all its cards.")
            }
            .toast($toast)
        }
    }

    private var boardGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(activeBoards) { board in
                    NavigationLink {
                        BoardDetailView(board: board)
                    } label: {
                        BoardCardView(board: board)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            archive(board)
                        } label: {
                            SwiftUI.Label("Archive", systemImage: "archivebox")
                        }
                        Button(role: .destructive) {
                            requestDelete(board)
                        } label: {
                            SwiftUI.Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(16)

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                Text(boardCountLabel)
            }
            .font(.footnote)
            .foregroundStyle(Theme.inkSoft)
            .padding(.bottom, 8)
        }
    }

    private var boardCountLabel: String {
        if proStore.isPro {
            return "\(activeBoards.count) board\(activeBoards.count == 1 ? "" : "s")"
        }
        return "\(activeBoards.count) of \(ProStore.freeBoardLimit) free boards"
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )
    }

    // MARK: - Actions

    private func startCreate() {
        if !proStore.isPro && activeBoards.count >= ProStore.freeBoardLimit {
            showPaywall = true
            Haptics.notify(.warning, enabled: settings.hapticsEnabled)
            return
        }
        showCreate = true
    }

    private func createBoard(name: String, color: Int, symbol: String, template: BoardTemplate) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? "Untitled Board" : trimmed
        let nextIndex = (activeBoards.map(\.sortIndex).max() ?? -1) + 1
        _ = BoardFactory.makeBoard(
            name: finalName,
            colorHex: color,
            symbolName: symbol,
            template: template,
            sortIndex: nextIndex,
            isPro: proStore.isPro,
            context: context
        )
        save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        toast = ToastMessage(symbol: "checkmark.circle.fill", text: "Board created")
    }

    private func archive(_ board: Board) {
        board.isArchived = true
        save()
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
        toast = ToastMessage(symbol: "archivebox.fill", text: "Archived")
    }

    private func requestDelete(_ board: Board) {
        if settings.confirmBeforeDelete {
            pendingDelete = board
        } else {
            delete(board)
        }
    }

    private func confirmDelete() {
        if let board = pendingDelete {
            delete(board)
        }
        pendingDelete = nil
    }

    private func delete(_ board: Board) {
        context.delete(board)
        save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        toast = ToastMessage(symbol: "trash.fill", text: "Deleted")
    }

    private func save() {
        try? context.save()
    }
}
