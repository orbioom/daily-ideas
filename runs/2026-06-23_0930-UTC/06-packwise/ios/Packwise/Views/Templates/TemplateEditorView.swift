import SwiftUI
import SwiftData

/// View / edit a template's items. Built-in templates are read-only for their
/// metadata but the user can still see items; custom templates are fully editable.
struct TemplateEditorView: View {
    @Bindable var template: Template
    @Environment(\.modelContext) private var context

    @State private var showingAddItem = false

    private var sortedItems: [TemplateItem] {
        template.items.sorted {
            if $0.category.sortIndex != $1.category.sortIndex {
                return $0.category.sortIndex < $1.category.sortIndex
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var categories: [PackCategory] {
        let present = Set(template.items.map(\.category))
        return PackCategory.allCases.filter { present.contains($0) }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    var body: some View {
        List {
            if !template.detail.isEmpty {
                Section {
                    Text(template.detail)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            if template.isBuiltIn {
                Section {
                    Label("Starter template — duplicate it to customise.",
                          systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            if template.items.isEmpty {
                Section {
                    Text("No items yet. Tap + to add one.")
                        .foregroundStyle(Theme.textSecondary)
                }
            } else {
                ForEach(categories) { category in
                    Section(category.title) {
                        ForEach(sortedItems.filter { $0.category == category }) { item in
                            HStack {
                                Text(item.name)
                                Spacer()
                                if item.quantity > 1 {
                                    Text("×\(item.quantity)")
                                        .foregroundStyle(Theme.textSecondary)
                                        .monospacedDigit()
                                }
                            }
                        }
                        .onDelete { offsets in
                            deleteItems(in: category, at: offsets)
                        }
                    }
                }
            }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddItem = true
                    } label: {
                        Label("Add item", systemImage: "plus")
                    }
                    Button {
                        duplicate()
                    } label: {
                        Label("Duplicate as editable", systemImage: "plus.square.on.square")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Template options")
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemSheet { name, qty, category in
                addItem(name: name, quantity: qty, category: category)
            }
        }
    }

    private func addItem(name: String, quantity: Int, category: PackCategory) {
        let order = (template.items.map(\.sortOrder).max() ?? 0) + 1
        let item = TemplateItem(name: name, quantity: quantity,
                                category: category, sortOrder: order)
        item.template = template
        template.items.append(item)
        context.insert(item)
        try? context.save()
    }

    private func deleteItems(in category: PackCategory, at offsets: IndexSet) {
        let inCategory = sortedItems.filter { $0.category == category }
        for index in offsets {
            guard inCategory.indices.contains(index) else { continue }
            let item = inCategory[index]
            template.items.removeAll { $0.id == item.id }
            context.delete(item)
        }
        try? context.save()
    }

    private func duplicate() {
        let copy = Template(
            name: template.name + " (Copy)",
            detail: template.detail,
            symbol: template.symbol,
            isBuiltIn: false
        )
        context.insert(copy)
        for (idx, item) in template.items.enumerated() {
            let ti = TemplateItem(name: item.name, quantity: item.quantity,
                                  category: item.category, sortOrder: idx)
            ti.template = copy
            copy.items.append(ti)
            context.insert(ti)
        }
        try? context.save()
    }
}
