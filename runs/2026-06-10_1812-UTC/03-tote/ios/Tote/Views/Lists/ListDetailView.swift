import SwiftUI
import SwiftData

struct ListDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var list: GroceryList
    @Query private var catalog: [CatalogItem]
    @AppStorage("hideChecked") private var hideChecked = false

    @State private var newItem = ""
    @State private var editingItem: ListItem?
    @FocusState private var addFocused: Bool

    private var groups: [(aisle: Aisle, items: [ListItem])] {
        let source = hideChecked ? list.activeItems : list.items
        return ToteEngine.grouped(source)
    }

    private var suggestions: [CatalogItem] {
        let q = newItem.lowercased().trimmingCharacters(in: .whitespaces)
        guard q.count >= 1 else { return [] }
        return catalog
            .filter { $0.nameKey.contains(q) && !list.activeItems.contains { i in i.name.lowercased() == $0.nameKey } }
            .sorted { $0.useCount > $1.useCount }
            .prefix(6).map { $0 }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                content
                addBar
            }
        }
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Toggle("Hide items in cart", isOn: $hideChecked)
                    if !list.checkedItems.isEmpty {
                        Button { clearChecked() } label: { Label("Clear cart items", systemImage: "trash") }
                    }
                    if list.items.contains(where: { $0.isChecked }) {
                        Button { uncheckAll() } label: { Label("Move all back", systemImage: "arrow.uturn.backward") }
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(item: $editingItem) { ItemEditorView(item: $0) }
    }

    @ViewBuilder private var content: some View {
        if list.items.isEmpty {
            Spacer()
            EmptyStateView(icon: "cart", title: "This list is empty",
                           message: "Add your first item below. Tote will file it in the right aisle.")
            Spacer()
        } else if groups.isEmpty {
            Spacer()
            EmptyStateView(icon: "checkmark.circle", title: "All in the cart",
                           message: "Everything's checked off. Nicely done.")
            Spacer()
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(groups, id: \.aisle) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: group.aisle.icon).font(.caption).foregroundStyle(group.aisle.tint)
                                Eyebrow(text: group.aisle.rawValue)
                                Spacer()
                                Text("\(group.items.count)").font(Brand.mono(11)).foregroundStyle(Brand.text3)
                            }
                            VStack(spacing: 0) {
                                ForEach(group.items) { item in
                                    itemRow(item)
                                    if item.id != group.items.last?.id {
                                        Divider().background(Brand.hairline).padding(.leading, 44)
                                    }
                                }
                            }
                            .glassCard(padding: 0)
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private func itemRow(_ item: ListItem) -> some View {
        Button {
            withAnimation(Brand.ease(0.25)) {
                item.isChecked.toggle()
                try? context.save()
            }
            Haptics.selection()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isChecked ? Brand.live : Brand.text3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.body)
                        .foregroundStyle(item.isChecked ? Brand.text3 : Brand.text)
                        .strikethrough(item.isChecked, color: Brand.text3)
                    if !item.note.isEmpty {
                        Text(item.note).font(.caption).foregroundStyle(Brand.text3)
                    }
                }
                Spacer()
                if item.quantity != 1 || !item.unit.isEmpty {
                    Text(item.quantityLabel).font(Brand.mono(13)).foregroundStyle(Brand.text2)
                }
                Button { editingItem = item } label: {
                    Image(systemName: "slider.horizontal.3").foregroundStyle(Brand.text3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit \(item.name)")
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(item.isChecked ? "in cart" : "to buy")")
        .contextMenu {
            Button(role: .destructive) {
                context.delete(item); try? context.save()
            } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private var addBar: some View {
        VStack(spacing: 8) {
            if !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.nameKey) { s in
                            Button {
                                add(name: s.displayName, aisle: s.aisle)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: s.aisle.icon).font(.caption2).foregroundStyle(s.aisle.tint)
                                    Text(s.displayName).font(.subheadline).foregroundStyle(Brand.text)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(0.4), lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill").foregroundStyle(Brand.text2)
                TextField("Add an item…", text: $newItem)
                    .focused($addFocused)
                    .submitLabel(.done)
                    .onSubmit { add(name: newItem, aisle: nil) }
                    .foregroundStyle(Brand.text)
                if !newItem.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button("Add") { add(name: newItem, aisle: nil) }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.magic)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }

    private func add(name: String, aisle: Aisle?) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let resolved = aisle ?? ToteEngine.resolveAisle(for: trimmed, catalog: catalog)
        ToteEngine.addItem(name: trimmed, quantity: 1, unit: "", aisle: resolved, to: list, in: context)
        ToteEngine.remember(name: trimmed, aisle: resolved, in: context, catalog: catalog)
        try? context.save()
        newItem = ""
        Haptics.tap()
    }

    private func clearChecked() {
        for item in list.checkedItems { context.delete(item) }
        try? context.save()
        Haptics.warning()
    }

    private func uncheckAll() {
        for item in list.items where item.isChecked { item.isChecked = false }
        try? context.save()
    }
}
