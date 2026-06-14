import SwiftUI
import SwiftData

struct PackingView: View {
    @Environment(\.modelContext) private var context
    @Bindable var trip: Trip

    @State private var newItemName = ""
    @State private var newItemCategory: PackCategory = .essentials
    @State private var showingTemplates = false
    @State private var paywallReason: PaywallReason?

    private var progress: PackingEngine.Progress { PackingEngine.progress(for: trip.packItems) }

    private var groupedCategories: [PackCategory] {
        let present = Set(trip.packItems.map { $0.category })
        return PackCategory.allCases.filter { present.contains($0) }.sorted { $0.order < $1.order }
    }

    private func items(in category: PackCategory) -> [PackItem] {
        trip.packItems
            .filter { $0.category == category }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        Group {
            if trip.packItems.isEmpty {
                ScrollView {
                    VStack(spacing: 16) {
                        EmptyStateView(symbol: "checklist.unchecked",
                                       title: "Nothing to pack yet",
                                       message: "Add items by hand, or start from a template to get a head start.",
                                       actionTitle: "Add from template",
                                       action: attemptTemplates)
                        addBar
                    }
                    .padding(.top, 8)
                }
            } else {
                List {
                    Section { progressHeader.listRowBackground(Color.clear) }
                    ForEach(groupedCategories, id: \.self) { category in
                        Section {
                            ForEach(items(in: category)) { item in
                                PackRow(item: item) { toggle(item) }
                                    .swipeActions {
                                        Button(role: .destructive) { delete(item) } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        } header: {
                            categoryHeader(category)
                        }
                    }
                    Section {
                        addBar.listRowBackground(Color.clear)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Packing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { attemptTemplates() } label: { Label("Add from template", systemImage: "square.stack.3d.up") }
                    if progress.packed > 0 {
                        Button(role: .destructive) { clearPacked() } label: {
                            Label("Clear packed items", systemImage: "trash")
                        }
                    }
                } label: { Image(systemName: "ellipsis.circle") }
                .accessibilityLabel("Packing options")
            }
        }
        .sheet(isPresented: $showingTemplates) {
            TemplatePickerView(trip: trip)
        }
        .sheet(item: $paywallReason) { PaywallView(reason: $0) }
    }

    private var progressHeader: some View {
        HStack(spacing: 16) {
            ProgressRing(fraction: progress.fraction,
                         size: 64, lineWidth: 8,
                         tint: progress.isComplete ? Theme.success : Theme.accent,
                         label: "\(Int((progress.fraction * 100).rounded()))%")
            VStack(alignment: .leading, spacing: 2) {
                Text(progress.isComplete ? "All packed!" : "\(progress.packed) of \(progress.total) packed")
                    .font(Theme.font(.headline))
                    .foregroundStyle(Theme.textPrimary)
                Text(progress.isComplete ? "You're ready to go." : "\(progress.total - progress.packed) left to pack")
                    .font(Theme.font(.subheadline))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Packing progress, \(progress.packed) of \(progress.total) packed")
    }

    private func categoryHeader(_ category: PackCategory) -> some View {
        let p = PackingEngine.progress(forCategory: category, in: trip.packItems)
        return HStack {
            Label(category.label, systemImage: category.symbol)
                .font(Theme.font(.subheadline, weight: .semibold))
                .foregroundStyle(category.tint)
            Spacer()
            Text("\(p.packed)/\(p.total)")
                .font(Theme.font(.caption, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var addBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField("Add an item…", text: $newItemName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addItem)
                Button(action: addItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(newItemName.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.textSecondary : Theme.accent)
                }
                .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Add packing item")
            }
            Picker("Category", selection: $newItemCategory) {
                ForEach(PackCategory.allCases.sorted { $0.order < $1.order }) { c in
                    Text(c.label).tag(c)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 4)
    }

    // MARK: Mutations

    private func addItem() {
        let name = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let item = PackItem(name: name, category: newItemCategory)
        context.insert(item)
        item.trip = trip
        newItemName = ""
        Haptics.tap()
    }

    private func toggle(_ item: PackItem) {
        item.packed.toggle()
        if item.packed { Haptics.success() } else { Haptics.select() }
    }

    private func delete(_ item: PackItem) {
        Haptics.tap()
        context.delete(item)
    }

    private func clearPacked() {
        Haptics.warning()
        for item in trip.packItems where item.packed {
            context.delete(item)
        }
    }

    private func attemptTemplates() {
        // The picker is always reachable; it gates non-default templates behind
        // Pro internally so free users can still apply their default template.
        Haptics.tap()
        showingTemplates = true
    }
}

// MARK: - Pack row

struct PackRow: View {
    @Bindable var item: PackItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: item.packed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.packed ? Theme.success : Theme.textSecondary)
                Text(item.name)
                    .font(Theme.font(.body))
                    .foregroundStyle(item.packed ? Theme.textSecondary : Theme.textPrimary)
                    .strikethrough(item.packed, color: Theme.textSecondary)
                Spacer()
                if item.quantity > 1 {
                    Text("×\(item.quantity)")
                        .font(Theme.font(.caption, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Capsule().fill(Theme.surfaceAlt))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.name)
        .accessibilityValue(item.packed ? "Packed" : "Not packed")
        .accessibilityHint("Double tap to toggle")
        .accessibilityAddTraits(item.packed ? [.isSelected] : [])
    }
}
