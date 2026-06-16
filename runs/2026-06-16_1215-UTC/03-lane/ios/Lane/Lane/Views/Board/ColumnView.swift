import SwiftUI
import SwiftData

/// A single board lane: header (name, count, WIP badge) + scrollable cards + add field.
struct ColumnView: View {
    @Bindable var column: BoardColumn
    let isDoneColumn: Bool
    let onOpenCard: (Card) -> Void
    let onMoveCard: (Card, BoardColumn) -> Void
    let onAddCard: (String, BoardColumn) -> Void
    let onEditColumn: (BoardColumn) -> Void
    let onToast: (ToastMessage) -> Void

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    @State private var newCardTitle = ""
    @State private var isAdding = false
    @State private var pendingDelete: Card?
    @FocusState private var addFieldFocused: Bool

    private var color: Color { Color(hex: UInt(max(0, column.colorHex))) }

    private var visibleCards: [Card] {
        let cards = column.orderedCards
        if settings.showCompletedCards { return cards }
        return cards.filter { !$0.isCompleted }
    }

    /// Sibling columns this card can be moved to.
    private var otherColumns: [BoardColumn] {
        (column.board?.orderedColumns ?? []).filter { $0.id != column.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            cardsList
            addArea
        }
        .padding(12)
        .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(column.isOverWipLimit ? Theme.bad.opacity(0.6) : Theme.hairline, lineWidth: 1)
        )
        .alert("Delete card?", isPresented: deleteAlertBinding) {
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let card = pendingDelete { performDelete(card) }
                pendingDelete = nil
            }
        } message: {
            Text("This permanently deletes \"\(pendingDelete?.title ?? "")\".")
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(column.name)
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            Text("\(column.cards.count)")
                .font(Theme.rounded(12, .bold))
                .foregroundStyle(Theme.inkSoft)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Theme.surface, in: Capsule())

            if column.hasWipLimit {
                wipBadge
            }

            Spacer()

            Menu {
                Button { onEditColumn(column) } label: {
                    SwiftUI.Label("Edit lane", systemImage: "slider.horizontal.3")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(Theme.inkSoft)
                    .padding(4)
            }
            .accessibilityLabel("Lane options for \(column.name)")
        }
    }

    private var wipBadge: some View {
        let exceeded = column.isOverWipLimit
        return Text("\(column.cards.count)/\(column.wipLimit)")
            .font(Theme.rounded(11, .bold))
            .foregroundStyle(exceeded ? .white : Theme.inkSoft)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(exceeded ? Theme.bad : Theme.surface, in: Capsule())
            .accessibilityLabel(exceeded ? "Over WIP limit, \(column.cards.count) of \(column.wipLimit)" : "WIP \(column.cards.count) of \(column.wipLimit)")
    }

    private var cardsList: some View {
        Group {
            if visibleCards.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "tray")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.inkSoft.opacity(0.7))
                    Text("No cards")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .accessibilityHidden(true)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(visibleCards) { card in
                            CardChipView(card: card, isDoneColumn: isDoneColumn)
                                .onTapGesture { onOpenCard(card) }
                                .contextMenu {
                                    cardContextMenu(for: card)
                                }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: 420)
            }
        }
    }

    @ViewBuilder
    private func cardContextMenu(for card: Card) -> some View {
        Button { onOpenCard(card) } label: {
            SwiftUI.Label("Open", systemImage: "arrow.up.right.square")
        }
        if !otherColumns.isEmpty {
            Menu {
                ForEach(otherColumns) { target in
                    Button {
                        onMoveCard(card, target)
                    } label: {
                        SwiftUI.Label(target.name, systemImage: "arrow.right")
                    }
                }
            } label: {
                SwiftUI.Label("Move to…", systemImage: "rectangle.2.swap")
            }
        }
        Button(role: .destructive) {
            deleteCard(card)
        } label: {
            SwiftUI.Label("Delete", systemImage: "trash")
        }
    }

    private var addArea: some View {
        Group {
            if isAdding {
                VStack(spacing: 6) {
                    TextField("Card title", text: $newCardTitle, axis: .vertical)
                        .font(.subheadline)
                        .focused($addFieldFocused)
                        .submitLabel(.done)
                        .onSubmit { commitAdd() }
                        .padding(8)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    HStack {
                        Button("Add") { commitAdd() }
                            .font(Theme.rounded(14, .semibold))
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.accent)
                        Button("Cancel") { cancelAdd() }
                            .font(Theme.rounded(14, .medium))
                            .foregroundStyle(Theme.inkSoft)
                        Spacer()
                    }
                }
            } else {
                Button {
                    isAdding = true
                    addFieldFocused = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Add a card")
                    }
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                }
                .accessibilityHint("Adds a card to \(column.name)")
            }
        }
    }

    // MARK: - Actions

    private func commitAdd() {
        let trimmed = newCardTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { cancelAdd(); return }
        onAddCard(trimmed, column)
        newCardTitle = ""
        // Keep adding mode on for fast entry of multiple cards.
        addFieldFocused = true
    }

    private func cancelAdd() {
        newCardTitle = ""
        isAdding = false
        addFieldFocused = false
    }

    private func deleteCard(_ card: Card) {
        if settings.confirmBeforeDelete {
            pendingDelete = card
        } else {
            performDelete(card)
        }
    }

    private func performDelete(_ card: Card) {
        let remaining = column.cards.filter { $0.id != card.id }
        context.delete(card)
        CardMover.compact(remaining)
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        onToast(ToastMessage(symbol: "trash.fill", text: "Card deleted"))
    }
}
