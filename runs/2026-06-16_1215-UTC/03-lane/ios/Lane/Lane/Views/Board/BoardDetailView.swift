import SwiftUI
import SwiftData

struct BoardDetailView: View {
    @Bindable var board: Board
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    @State private var selectedCard: Card?
    @State private var showRenameBoard = false
    @State private var renameText = ""
    @State private var editColumn: BoardColumn?
    @State private var showAddColumn = false
    @State private var newColumnName = ""
    @State private var manageColumns = false
    @State private var toast: ToastMessage?

    private var orderedColumns: [BoardColumn] { board.orderedColumns }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 14) {
                ForEach(orderedColumns) { column in
                    ColumnView(
                        column: column,
                        isDoneColumn: board.doneColumn?.id == column.id,
                        onOpenCard: { selectedCard = $0 },
                        onMoveCard: moveCard,
                        onAddCard: addCard,
                        onEditColumn: { editColumn = $0 },
                        onToast: { toast = $0 }
                    )
                    .frame(width: 280)
                }

                addColumnTile
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(board.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        renameText = board.name
                        showRenameBoard = true
                    } label: {
                        SwiftUI.Label("Rename board", systemImage: "pencil")
                    }
                    Button {
                        manageColumns = true
                    } label: {
                        SwiftUI.Label("Reorder lanes", systemImage: "arrow.up.arrow.down")
                    }
                    Button {
                        startAddColumn()
                    } label: {
                        SwiftUI.Label("Add lane", systemImage: "plus.rectangle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Board options")
            }
        }
        .sheet(item: $selectedCard) { card in
            CardDetailView(card: card)
        }
        .sheet(item: $editColumn) { column in
            ColumnEditView(column: column, board: board)
        }
        .sheet(isPresented: $manageColumns) {
            ManageColumnsView(board: board)
        }
        .alert("Rename board", isPresented: $showRenameBoard) {
            TextField("Board name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Save") { renameBoard() }
        }
        .alert("Add lane", isPresented: $showAddColumn) {
            TextField("Lane name", text: $newColumnName)
            Button("Cancel", role: .cancel) {}
            Button("Add") { addColumn() }
        }
        .toast($toast)
    }

    private var addColumnTile: some View {
        Button {
            startAddColumn()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                Text("Add lane")
                    .font(Theme.rounded(14, .semibold))
            }
            .foregroundStyle(Theme.accent)
            .frame(width: 150, height: 120)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .fill(Theme.surface.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(Theme.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add lane")
    }

    // MARK: - Actions

    private func moveCard(_ card: Card, to target: BoardColumn) {
        withAnimation {
            CardMover.move(card, to: target, context: context)
        }
        save()
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
        if board.doneColumn?.id == target.id {
            toast = ToastMessage(symbol: "checkmark.seal.fill", text: "Card completed")
        }
    }

    private func addCard(_ title: String, to column: BoardColumn) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextIndex = (column.cards.map(\.sortIndex).max() ?? -1) + 1
        let card = Card(title: trimmed, sortIndex: nextIndex, column: column)
        context.insert(card)
        column.cards.append(card)
        CardMover.updateCompletion(for: card, in: column)
        save()
        Haptics.impact(.light, enabled: settings.hapticsEnabled)
    }

    private func renameBoard() {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        board.name = trimmed
        save()
        Haptics.selection(enabled: settings.hapticsEnabled)
    }

    private func startAddColumn() {
        newColumnName = ""
        showAddColumn = true
    }

    private func addColumn() {
        let trimmed = newColumnName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // New column becomes the new last column; previous done-column cards must
        // have their completion re-evaluated.
        let nextIndex = (board.columns.map(\.sortIndex).max() ?? -1) + 1
        let colorHex = Palette.columnColors[safe: board.columns.count] ?? 0x8E97A6
        let column = BoardColumn(name: trimmed, sortIndex: nextIndex, colorHex: colorHex, board: board)
        context.insert(column)
        board.columns.append(column)
        // Recompute completion across all columns since "done" moved.
        for col in board.orderedColumns {
            for card in col.cards {
                CardMover.updateCompletion(for: card, in: col)
            }
        }
        save()
        Haptics.impact(.light, enabled: settings.hapticsEnabled)
        toast = ToastMessage(symbol: "plus.circle.fill", text: "Lane added")
    }

    private func save() {
        try? context.save()
    }
}
