import SwiftUI
import SwiftData

struct ListsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \GroceryList.sortIndex) private var lists: [GroceryList]
    @State private var showingNew = false
    @State private var newName = ""
    @State private var renameTarget: GroceryList?

    private var active: [GroceryList] { lists.filter { !$0.isArchived } }
    private var archived: [GroceryList] { lists.filter { $0.isArchived } }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if active.isEmpty && archived.isEmpty {
                    EmptyStateView(icon: "checklist", title: "No lists yet",
                                   message: "Create your first shopping list to get started.")
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(active) { list in
                                NavigationLink(value: list) { listCard(list) }
                                    .buttonStyle(.plain)
                                    .contextMenu { menu(for: list) }
                            }
                            if !archived.isEmpty {
                                Eyebrow(text: "Archived")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 8)
                                ForEach(archived) { list in
                                    NavigationLink(value: list) { listCard(list) }
                                        .buttonStyle(.plain)
                                        .contextMenu { menu(for: list) }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Lists")
            .navigationDestination(for: GroceryList.self) { ListDetailView(list: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { newName = ""; showingNew = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New list")
                }
            }
            .alert("New list", isPresented: $showingNew) {
                TextField("List name", text: $newName)
                Button("Create") { createList() }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Rename list", isPresented: Binding(get: { renameTarget != nil },
                                                       set: { if !$0 { renameTarget = nil } })) {
                TextField("List name", text: $newName)
                Button("Save") {
                    if let t = renameTarget, !newName.trimmingCharacters(in: .whitespaces).isEmpty {
                        t.name = newName.trimmingCharacters(in: .whitespaces)
                        try? context.save()
                    }
                    renameTarget = nil
                }
                Button("Cancel", role: .cancel) { renameTarget = nil }
            }
        }
    }

    private func listCard(_ list: GroceryList) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(list.name).font(.headline).foregroundStyle(Brand.text)
                Spacer()
                if list.isArchived {
                    Image(systemName: "archivebox.fill").foregroundStyle(Brand.text3)
                }
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(Brand.text3)
            }
            HStack(spacing: 8) {
                Text("\(list.activeItems.count) to buy")
                    .font(Brand.mono(12)).foregroundStyle(Brand.text2)
                if !list.checkedItems.isEmpty {
                    Text("· \(list.checkedItems.count) in cart")
                        .font(Brand.mono(12)).foregroundStyle(Brand.live)
                }
            }
            if !list.items.isEmpty {
                ProgressView(value: list.progress)
                    .tint(Brand.live)
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(list.name), \(list.activeItems.count) items to buy")
    }

    @ViewBuilder private func menu(for list: GroceryList) -> some View {
        Button { newName = list.name; renameTarget = list } label: { Label("Rename", systemImage: "pencil") }
        Button { list.isArchived.toggle(); try? context.save() } label: {
            Label(list.isArchived ? "Unarchive" : "Archive",
                  systemImage: list.isArchived ? "tray.and.arrow.up" : "archivebox")
        }
        Button(role: .destructive) {
            context.delete(list); try? context.save(); Haptics.warning()
        } label: { Label("Delete", systemImage: "trash") }
    }

    private func createList() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let next = (lists.map { $0.sortIndex }.max() ?? 0) + 1
        context.insert(GroceryList(name: trimmed, sortIndex: next))
        try? context.save()
        Haptics.success()
    }
}
