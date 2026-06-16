import SwiftUI
import SwiftData

struct CardDetailView: View {
    @Bindable var card: Card
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var proStore: ProStore

    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var newChecklistText = ""
    @State private var showLabelPicker = false
    @State private var showDeleteConfirm = false
    @FocusState private var checklistFocused: Bool

    init(card: Card) {
        self.card = card
        _hasDueDate = State(initialValue: card.dueDate != nil)
        _dueDate = State(initialValue: card.dueDate ?? DateUtils.startOfDay(Date()))
    }

    private var board: Board? { card.column?.board }
    private var moveTargets: [BoardColumn] {
        (board?.orderedColumns ?? []).filter { $0.id != card.column?.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                propertiesSection
                labelsSection
                checklistSection
                moveSection
                deleteSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        commit()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showLabelPicker) {
                LabelPickerView(card: card)
            }
            .alert("Delete card?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { deleteCard() }
            } message: {
                Text("This permanently deletes \"\(card.title)\".")
            }
            .onChange(of: hasDueDate) { _, newValue in
                if newValue {
                    card.dueDate = DateUtils.startOfDay(dueDate)
                } else {
                    card.dueDate = nil
                }
                saveQuietly()
            }
            .onChange(of: dueDate) { _, newValue in
                if hasDueDate {
                    card.dueDate = DateUtils.startOfDay(newValue)
                    saveQuietly()
                }
            }
        }
    }

    // MARK: - Sections

    private var titleSection: some View {
        Section("Title") {
            TextField("Card title", text: $card.title, axis: .vertical)
                .font(Theme.rounded(17, .semibold))
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
                TextField("Add notes…", text: $card.notes, axis: .vertical)
                    .lineLimit(3...8)
            }
        }
    }

    private var propertiesSection: some View {
        Section("Properties") {
            Picker("Priority", selection: priorityBinding) {
                ForEach(Priority.allCases) { p in
                    SwiftUI.Label(p.rawValue, systemImage: p.symbol).tag(p)
                }
            }

            Toggle("Due date", isOn: $hasDueDate)
            if hasDueDate {
                DatePicker("Due", selection: $dueDate, displayedComponents: .date)
            }
        }
    }

    private var labelsSection: some View {
        Section("Labels") {
            if card.labels.isEmpty {
                Text("No labels")
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(card.labels) { label in
                            LabelChip(name: label.name, colorHex: label.colorHex)
                        }
                    }
                }
            }
            Button {
                showLabelPicker = true
            } label: {
                HStack {
                    SwiftUI.Label("Edit labels", systemImage: "tag")
                    if !proStore.isPro {
                        Spacer()
                        ProLockBadge()
                    }
                }
            }
        }
    }

    private var checklistSection: some View {
        Section {
            if !card.checklist.isEmpty {
                ProgressView(value: card.checklistProgress) {
                    HStack {
                        Text("Checklist")
                        Spacer()
                        Text("\(card.checklistDoneCount)/\(card.checklist.count)")
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .font(Theme.rounded(13, .semibold))
                }
                .tint(Theme.accent)

                ForEach(card.orderedChecklist) { item in
                    Button {
                        toggle(item)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.isDone ? Theme.good : Theme.inkSoft)
                            Text(item.text)
                                .foregroundStyle(item.isDone ? Theme.inkSoft : Theme.ink)
                                .strikethrough(item.isDone)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(item.isDone ? [.isSelected] : [])
                }
                .onDelete(perform: deleteChecklistItems)
                .onMove(perform: moveChecklistItems)
            }

            HStack {
                TextField("Add a step", text: $newChecklistText)
                    .focused($checklistFocused)
                    .submitLabel(.done)
                    .onSubmit { addChecklistItem() }
                Button {
                    addChecklistItem()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Theme.accent)
                }
                .disabled(newChecklistText.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Add checklist step")
            }
        } header: {
            Text("Checklist")
        }
    }

    private var moveSection: some View {
        Section("Lane") {
            if let current = card.column {
                HStack {
                    Text("Current")
                    Spacer()
                    Text(current.name)
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            if moveTargets.isEmpty {
                Text("No other lanes")
                    .foregroundStyle(Theme.inkSoft)
            } else {
                Menu {
                    ForEach(moveTargets) { target in
                        Button {
                            move(to: target)
                        } label: {
                            SwiftUI.Label(target.name, systemImage: "arrow.right")
                        }
                    }
                } label: {
                    SwiftUI.Label("Move to…", systemImage: "rectangle.2.swap")
                }
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                if settings.confirmBeforeDelete {
                    showDeleteConfirm = true
                } else {
                    deleteCard()
                }
            } label: {
                SwiftUI.Label("Delete card", systemImage: "trash")
            }
        }
    }

    // MARK: - Bindings & actions

    private var priorityBinding: Binding<Priority> {
        Binding(
            get: { card.priority },
            set: { card.priority = $0; saveQuietly() }
        )
    }

    private func toggle(_ item: ChecklistItem) {
        item.isDone.toggle()
        saveQuietly()
        Haptics.selection(enabled: settings.hapticsEnabled)
    }

    private func addChecklistItem() {
        let trimmed = newChecklistText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextIndex = (card.checklist.map(\.sortIndex).max() ?? -1) + 1
        let item = ChecklistItem(text: trimmed, sortIndex: nextIndex, card: card)
        context.insert(item)
        card.checklist.append(item)
        newChecklistText = ""
        checklistFocused = true
        saveQuietly()
        Haptics.impact(.light, enabled: settings.hapticsEnabled)
    }

    private func deleteChecklistItems(at offsets: IndexSet) {
        let ordered = card.orderedChecklist
        for index in offsets {
            if let item = ordered[safe: index] {
                context.delete(item)
            }
        }
        CardMover.compactChecklist(card.checklist)
        saveQuietly()
    }

    private func moveChecklistItems(from offsets: IndexSet, to destination: Int) {
        CardMover.reorderChecklist(in: card, from: offsets, to: destination)
        saveQuietly()
    }

    private func move(to target: BoardColumn) {
        CardMover.move(card, to: target, context: context)
        saveQuietly()
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
    }

    private func deleteCard() {
        let siblings = card.column?.cards.filter { $0.id != card.id } ?? []
        context.delete(card)
        CardMover.compact(siblings)
        saveQuietly()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func commit() {
        card.title = card.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Untitled"
            : card.title
        saveQuietly()
    }

    private func saveQuietly() {
        try? context.save()
    }
}
