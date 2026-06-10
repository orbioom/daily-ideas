import SwiftUI
import SwiftData

/// The shared scrapbook: moments worth keeping, newest first.
struct MemoriesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Memory.date, order: .reverse) private var memories: [Memory]
    @State private var editorTarget: Memory?
    @State private var showNew = false
    @State private var deleteTarget: Memory?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if memories.isEmpty {
                    EmptyStateView(
                        icon: "photo.on.rectangle.angled",
                        title: "No memories yet",
                        message: "Log the small wins and the big days — future-you will thank present-you."
                    )
                } else {
                    List {
                        ForEach(grouped, id: \.key) { month, items in
                            Section {
                                ForEach(items) { memory in
                                    Button {
                                        editorTarget = memory
                                    } label: {
                                        row(memory)
                                    }
                                    .buttonStyle(.plain)
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            deleteTarget = memory
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                Eyebrow(text: month)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Memories")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNew = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add memory")
                }
            }
            .sheet(isPresented: $showNew) { MemoryEditorView(memory: nil) }
            .sheet(item: $editorTarget) { MemoryEditorView(memory: $0) }
            .alert("Delete this memory?", isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let m = deleteTarget {
                        context.delete(m)
                        Haptics.warning()
                    }
                    deleteTarget = nil
                }
                Button("Cancel", role: .cancel) { deleteTarget = nil }
            }
        }
    }

    private var grouped: [(key: String, value: [Memory])] {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        var order: [String] = []
        var buckets: [String: [Memory]] = [:]
        for m in memories {
            let key = fmt.string(from: m.date)
            if buckets[key] == nil { order.append(key) }
            buckets[key, default: []].append(m)
        }
        return order.map { ($0, buckets[$0] ?? []) }
    }

    private func row(_ memory: Memory) -> some View {
        HStack(spacing: 12) {
            Text(memory.emoji)
                .font(.title2)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(memory.title)
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                if !memory.note.isEmpty {
                    Text(memory.note)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .lineLimit(2)
                }
                Text(memory.date, format: .dateTime.weekday(.abbreviated).day().month())
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens this memory for editing")
    }
}

struct MemoryEditorView: View {
    let memory: Memory?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private static let emojiChoices = ["💛", "🥂", "🌅", "✈️", "🏡", "🍝", "🎶", "🌊", "⛰️", "🎁", "😂", "💍"]

    @State private var title = ""
    @State private var note = ""
    @State private var emoji = "💛"
    @State private var date = Date()
    @State private var error: String?
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Moment") {
                    TextField("Title (e.g. The lighthouse picnic)", text: $title)
                    DatePicker("When", selection: $date, displayedComponents: .date)
                    TextField("What happened?", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Mood") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(Self.emojiChoices, id: \.self) { choice in
                            Button {
                                emoji = choice
                                Haptics.selection()
                            } label: {
                                Text(choice)
                                    .font(.title2)
                                    .padding(6)
                                    .background(emoji == choice ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.clear),
                                                in: Circle())
                                    .overlay(Circle().strokeBorder(emoji == choice ? Brand.live : Color.clear, lineWidth: 1.5))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Emoji \(choice)")
                            .accessibilityAddTraits(emoji == choice ? .isSelected : [])
                        }
                    }
                }
                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(Brand.danger)
                    }
                }
            }
            .navigationTitle(memory == nil ? "New Memory" : "Edit Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                if let m = memory {
                    title = m.title
                    note = m.note
                    emoji = m.emoji
                    date = m.date
                }
            }
        }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else {
            error = "Give the memory a title."
            return
        }
        if let m = memory {
            m.title = t
            m.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            m.emoji = emoji
            m.date = date
        } else {
            context.insert(Memory(date: date, title: t,
                                  note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                                  emoji: emoji))
        }
        Haptics.success()
        dismiss()
    }
}
