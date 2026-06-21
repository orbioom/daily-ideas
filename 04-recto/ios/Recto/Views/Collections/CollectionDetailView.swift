import SwiftUI
import SwiftData

struct CollectionDetailView: View {
    let collection: Collection
    @Query private var allEntries: [BulletEntry]
    @Query private var settingsArr: [RectoSettings]
    @Environment(\.modelContext) private var ctx
    @State private var newEntryText: String = ""
    @State private var newBulletType: BulletType = .task
    @State private var isAddingEntry: Bool = false
    @FocusState private var isTextFieldFocused: Bool

    private var fontStyle: String { settingsArr.first?.fontStyle ?? "sans" }
    private var hapticEnabled: Bool { settingsArr.first?.hapticEnabled ?? true }

    private var collectionEntries: [BulletEntry] {
        allEntries
            .filter { $0.collectionId == collection.id }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            RectoTheme.paperBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                if collectionEntries.isEmpty && !isAddingEntry {
                    EmptyStateView(
                        icon: collection.icon,
                        title: "No Entries Yet",
                        subtitle: "Start adding tasks, events, and notes\nto \(collection.name).",
                        actionTitle: "Add First Entry",
                        action: {
                            isAddingEntry = true
                            isTextFieldFocused = true
                        }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(collectionEntries) { entry in
                                BulletRowView(
                                    entry: entry,
                                    fontStyle: fontStyle,
                                    onToggleComplete: {
                                        if entry.bulletTypeEnum == .task {
                                            if hapticEnabled {
                                                let gen = UIImpactFeedbackGenerator(style: .light)
                                                gen.impactOccurred()
                                            }
                                            toggleComplete(entry)
                                        }
                                    },
                                    onToggleStar: {
                                        entry.isStarred.toggle()
                                        try? ctx.save()
                                    }
                                )
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        ctx.delete(entry)
                                        try? ctx.save()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    if entry.bulletTypeEnum == .task && entry.statusEnum == .open {
                                        Button {
                                            entry.status = TaskStatus.complete.rawValue
                                            try? ctx.save()
                                        } label: {
                                            Label("Complete", systemImage: "checkmark.circle")
                                        }
                                        .tint(RectoTheme.eventColor)
                                    }
                                }

                                Divider()
                                    .padding(.leading, 52)
                                    .overlay(RectoTheme.ruleLineColor.opacity(0.6))
                            }

                            Color.clear.frame(height: 80)
                        }
                    }
                }
            }

            // Add entry bar
            addEntryBar
                .background(RectoTheme.paperBackground.opacity(0.97))
                .overlay(alignment: .top) {
                    Divider().overlay(RectoTheme.ruleLineColor)
                }
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: collection.colorHex).opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: collection.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: collection.colorHex))
                }
            }
        }
    }

    private func toggleComplete(_ entry: BulletEntry) {
        if entry.statusEnum == .open {
            entry.status = TaskStatus.complete.rawValue
        } else if entry.statusEnum == .complete {
            entry.status = TaskStatus.open.rawValue
        }
        try? ctx.save()
    }

    private var addEntryBar: some View {
        VStack(spacing: 0) {
            if isAddingEntry {
                Picker("Type", selection: $newBulletType) {
                    ForEach(BulletType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 10)

                HStack(spacing: 12) {
                    Text(newBulletSymbol)
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundStyle(RectoTheme.bulletColor(for: newBulletType))
                        .frame(width: 28)

                    TextField("Add entry…", text: $newEntryText, axis: .vertical)
                        .font(.system(size: 16, weight: .regular, design: fontStyle == "serif" ? .serif : .default))
                        .focused($isTextFieldFocused)
                        .lineLimit(1...4)
                        .submitLabel(.done)
                        .onSubmit { addEntry() }

                    Button { addEntry() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(
                                newEntryText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color(red: 0.75, green: 0.73, blue: 0.70)
                                : Color(hex: collection.colorHex)
                            )
                    }
                    .disabled(newEntryText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            } else {
                HStack {
                    Spacer()
                    Button {
                        isAddingEntry = true
                        isTextFieldFocused = true
                    } label: {
                        Label("Add Entry", systemImage: "plus")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(hex: collection.colorHex))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(hex: collection.colorHex).opacity(0.1))
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isAddingEntry)
    }

    private var newBulletSymbol: String {
        switch newBulletType {
        case .task: return "•"
        case .event: return "○"
        case .note: return "–"
        }
    }

    private func addEntry() {
        let trimmed = newEntryText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let maxOrder = collectionEntries.map(\.sortOrder).max() ?? -1
        let entry = BulletEntry(
            date: .now,
            bulletType: newBulletType,
            text: trimmed,
            collectionId: collection.id,
            sortOrder: maxOrder + 1
        )
        ctx.insert(entry)
        try? ctx.save()
        newEntryText = ""
        isAddingEntry = false
    }
}
