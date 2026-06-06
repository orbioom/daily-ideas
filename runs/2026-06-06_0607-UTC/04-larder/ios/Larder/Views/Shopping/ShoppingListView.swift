import SwiftUI
import SwiftData

/// The shopping list: low-stock items appear automatically and merge with hand-typed
/// entries (de-duped by name). Checking an auto entry off restocks its source item.
struct ShoppingListView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query private var items: [Item]
    @Query(sort: \ShoppingListEntry.createdAt) private var stored: [ShoppingListEntry]

    @State private var newEntryText = ""
    @State private var toast: String?

    // MARK: - Derived rows

    /// Items currently at/below threshold, as low-stock seeds for the list.
    private var lowStockSeeds: [(id: UUID, name: String, detail: String)] {
        items.filter { $0.isLowStock }.map { item in
            let detail = "Low — \(item.quantityLabel) left"
            return (id: item.id, name: item.name, detail: detail)
        }
    }

    /// Stored entries converted into merge rows.
    private var storedRows: [ExpiryLogic.Row] {
        stored.map { entry in
            ExpiryLogic.Row(
                id: entry.id,
                name: entry.name,
                detail: entry.isManual
                    ? (entry.desiredText.isEmpty ? "Added by you" : "Buy \(entry.desiredText)")
                    : "Low stock",
                isManual: entry.isManual,
                isChecked: entry.isChecked,
                itemID: entry.itemID)
        }
    }

    private var rows: [ExpiryLogic.Row] {
        ExpiryLogic.mergeRows(stored: storedRows, lowStockItems: lowStockSeeds)
    }

    private var pending: [ExpiryLogic.Row] { rows.filter { !$0.isChecked } }
    private var done: [ExpiryLogic.Row] { rows.filter { $0.isChecked } }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Brand.pageBackground
                content
                if let toast {
                    ToastView(message: toast)
                        .id(toast)
                }
            }
            .navigationTitle("Shopping")
            .toolbar {
                if !done.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear done") { clearDone() }
                            .tint(Brand.text2)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                addRow
                if rows.isEmpty {
                    EmptyStateView(
                        icon: "cart",
                        title: "Your list is clear",
                        message: "Items that drop to their low-stock level show up here automatically. Add anything else by hand above.")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)
                } else {
                    if !pending.isEmpty {
                        section(title: "To buy", rows: pending)
                    }
                    if !done.isEmpty {
                        section(title: "Bought", rows: done)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
    }

    private var addRow: some View {
        GlassCard(padding: 12) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Brand.text3)
                    .accessibilityHidden(true)
                TextField("Add an item", text: $newEntryText)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit(addManual)
                if !trimmedNew.isEmpty {
                    Button("Add", action: addManual)
                        .font(.subheadline.weight(.semibold))
                        .tint(Brand.text)
                }
            }
        }
    }

    private func section(title: String, rows: [ExpiryLogic.Row]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: title)
            VStack(spacing: 10) {
                ForEach(rows) { row in
                    ShoppingRowView(row: row,
                                    onToggle: { toggle(row) },
                                    onDelete: row.isManual ? { delete(row) } : nil)
                }
            }
        }
    }

    // MARK: - Actions

    private var trimmedNew: String {
        newEntryText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addManual() {
        let name = trimmedNew
        guard !name.isEmpty else { return }
        // De-dupe against existing rows (auto or manual) by normalized name.
        let key = name.lowercased()
        let exists = rows.contains { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == key }
        if exists {
            newEntryText = ""
            flash("Already on your list")
            return
        }
        context.insert(ShoppingListEntry(name: name, isManual: true))
        try? context.save()
        newEntryText = ""
        Haptics.impact(enabled: settings.hapticsEnabled)
    }

    /// Toggling a checked state. For an auto (low-stock) row being checked, we restock
    /// its source item to one above its threshold and remove it from the active list.
    private func toggle(_ row: ExpiryLogic.Row) {
        var didCheck = false
        if let entry = stored.first(where: { $0.id == row.id }) {
            entry.isChecked.toggle()
            didCheck = entry.isChecked
            if entry.isChecked { restock(entry.itemID) }
            try? context.save()
        } else {
            // A purely-auto row (not yet persisted). Persist it as a checked auto entry
            // so the checked state is durable, and restock its item.
            let entry = ShoppingListEntry(
                name: row.name,
                isManual: false,
                itemID: row.itemID,
                isChecked: true)
            context.insert(entry)
            restock(row.itemID)
            try? context.save()
            didCheck = true
        }
        Haptics.success(enabled: settings.hapticsEnabled)
        if didCheck {
            let restocked = row.itemID != nil
            flash(restocked ? "Restocked \(row.name)" : "Bought \(row.name)")
        } else {
            flash("Back on the list")
        }
    }

    /// Restocks a source item to just above its low-stock threshold so it leaves the list.
    private func restock(_ itemID: UUID?) {
        guard let itemID, let item = items.first(where: { $0.id == itemID }) else { return }
        if item.quantity <= item.lowStockThreshold {
            item.quantity = item.lowStockThreshold + 1
            item.updatedAt = .now
        }
    }

    private func delete(_ row: ExpiryLogic.Row) {
        guard let entry = stored.first(where: { $0.id == row.id }) else { return }
        context.delete(entry)
        try? context.save()
        Haptics.impact(enabled: settings.hapticsEnabled)
    }

    private func clearDone() {
        for entry in stored where entry.isChecked {
            context.delete(entry)
        }
        try? context.save()
        Haptics.impact(enabled: settings.hapticsEnabled)
    }

    private func flash(_ message: String) {
        withAnimation(Brand.ease(0.25)) { toast = message }
        let target = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            if toast == target {
                withAnimation(Brand.ease(0.25)) { toast = nil }
            }
        }
    }
}

/// A single shopping-list line with a check control and optional swipe-to-delete.
private struct ShoppingRowView: View {
    let row: ExpiryLogic.Row
    let onToggle: () -> Void
    let onDelete: (() -> Void)?

    var body: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: row.isChecked ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(row.isChecked ? Brand.fresh : Brand.text3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(row.isChecked ? "Mark as not bought" : "Mark as bought")

                VStack(alignment: .leading, spacing: 3) {
                    Text(row.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(row.isChecked ? Brand.text3 : Brand.text)
                        .strikethrough(row.isChecked, color: Brand.text3)
                    HStack(spacing: 6) {
                        Image(systemName: row.isManual ? "hand.point.up.left.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 10))
                        Text(row.detail)
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(row.isManual ? Brand.text2 : Brand.amber)
                }
                Spacer(minLength: 4)
                if let onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(Brand.text3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(row.name)")
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ShoppingListView()
        .environment(SettingsStore())
        .modelContainer(PreviewData.container)
}
