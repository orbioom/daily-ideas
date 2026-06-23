import SwiftUI
import SwiftData

/// Tonight's wind-down checklist. Steps auto-reset each night. Full CRUD on the
/// routine itself plus reordering and enable/disable.
struct RoutineView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WindDownItem.order) private var items: [WindDownItem]
    @Query private var settingsList: [SleepSettings]

    @State private var showEditor = false
    @State private var editingItem: WindDownItem?
    @State private var isManaging = false

    private var hapticsOn: Bool { settingsList.first?.hapticsEnabled ?? true }
    private var night: Date { Calendar.current.startOfDay(for: .now) }

    private var enabledItems: [WindDownItem] { items.filter { $0.isEnabled } }
    private var doneCount: Int { enabledItems.filter { $0.isDone(on: night) }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                DriftBackground()
                if items.isEmpty {
                    EmptyStateView(
                        symbol: "checklist",
                        title: "No routine yet",
                        message: "Build a calming wind-down sequence. Drift will remind you when to begin it each night.",
                        actionTitle: "Add a step",
                        action: { showEditor = true }
                    )
                } else {
                    list
                }
            }
            .navigationTitle("Wind-Down")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !items.isEmpty {
                        Button(isManaging ? "Done" : "Manage") {
                            withAnimation { isManaging.toggle() }
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showEditor = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add a step")
                }
            }
            .sheet(isPresented: $showEditor) {
                WindDownEditorView(item: nil, nextOrder: (items.map { $0.order }.max() ?? -1) + 1)
            }
            .sheet(item: $editingItem) { item in
                WindDownEditorView(item: item, nextOrder: item.order)
            }
        }
    }

    private var list: some View {
        List {
            Section {
                ProgressHeader(done: doneCount, total: enabledItems.count)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
            }

            Section(isManaging ? "All steps" : "Tonight") {
                ForEach(isManaging ? items : enabledItems) { item in
                    row(for: item)
                        .listRowBackground(Theme.card)
                }
                .onDelete(perform: deleteAction)
                .onMove(perform: moveAction)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(isManaging ? .active : .inactive))
    }

    @ViewBuilder
    private func row(for item: WindDownItem) -> some View {
        if isManaging {
            Button {
                editingItem = item
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: item.symbol)
                        .foregroundStyle(Theme.dusk)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .foregroundStyle(Theme.textPrimary)
                        if !item.detail.isEmpty {
                            Text(item.detail).font(.caption).foregroundStyle(Theme.textSecondary)
                        }
                    }
                    Spacer()
                    Toggle("", isOn: enabledBinding(item))
                        .labelsHidden()
                        .accessibilityLabel("\(item.title) enabled")
                }
            }
            .buttonStyle(.plain)
        } else {
            let done = item.isDone(on: night)
            Button {
                toggle(item)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(done ? Theme.good : Theme.textSecondary.opacity(0.5))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .foregroundStyle(Theme.textPrimary)
                            .strikethrough(done, color: Theme.textSecondary)
                        if !item.detail.isEmpty {
                            Text(item.detail).font(.caption).foregroundStyle(Theme.textSecondary)
                        }
                    }
                    Spacer()
                    Image(systemName: item.symbol)
                        .foregroundStyle(Theme.dusk.opacity(0.7))
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(item.title)
            .accessibilityValue(done ? "Done" : "Not done")
            .accessibilityHint("Double tap to toggle")
            .accessibilityAddTraits(done ? [.isSelected, .isButton] : .isButton)
        }
    }

    private func enabledBinding(_ item: WindDownItem) -> Binding<Bool> {
        Binding(
            get: { item.isEnabled },
            set: { item.isEnabled = $0; try? context.save() }
        )
    }

    private func toggle(_ item: WindDownItem) {
        if item.isDone(on: night) {
            item.completedOn = nil
        } else {
            item.completedOn = night
            Haptics.tap(hapticsOn)
            // Celebrate completing the whole routine.
            if enabledItems.allSatisfy({ $0.isDone(on: night) }) {
                Haptics.success(hapticsOn)
            }
        }
        try? context.save()
    }

    private var deleteAction: ((IndexSet) -> Void)? {
        isManaging ? delete : nil
    }

    private var moveAction: ((IndexSet, Int) -> Void)? {
        isManaging ? move : nil
    }

    private func delete(_ offsets: IndexSet) {
        let source = items
        for index in offsets where source.indices.contains(index) {
            context.delete(source[index])
        }
        try? context.save()
    }

    private func move(_ offsets: IndexSet, to destination: Int) {
        var reordered = items
        reordered.move(fromOffsets: offsets, toOffset: destination)
        for (idx, item) in reordered.enumerated() { item.order = idx }
        try? context.save()
    }
}

private struct ProgressHeader: View {
    let done: Int
    let total: Int

    private var fraction: Double { total == 0 ? 0 : Double(done) / Double(total) }

    var body: some View {
        VStack(spacing: 10) {
            if total == 0 {
                Text("Enable some steps to build tonight's routine.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
            } else {
                HStack {
                    Text(done == total ? "Routine complete 🌙" : "\(done) of \(total) done")
                        .font(.headline)
                        .foregroundStyle(done == total ? Theme.good : Theme.textPrimary)
                    Spacer()
                    Text("\(Int(fraction * 100))%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
                ProgressView(value: fraction)
                    .tint(done == total ? Theme.good : Theme.accent)
            }
        }
        .padding()
        .driftCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Wind-down progress")
        .accessibilityValue(total == 0 ? "No steps enabled" : "\(done) of \(total) complete")
    }
}
