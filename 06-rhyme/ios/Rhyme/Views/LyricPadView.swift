import SwiftUI
import SwiftData

extension LyricEntry: Identifiable {
    public var id: PersistentIdentifier { persistentModelID }
}

struct LyricPadView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \LyricEntry.dateModified, order: .reverse) private var entries: [LyricEntry]
    @State private var selectedEntry: LyricEntry?

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    entryList
                }
            }
            .navigationTitle("Lyric Pad")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { createEntry() } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(item: $selectedEntry) { entry in
                LyricEditorView(entry: entry)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text").font(.system(size: 60)).foregroundStyle(.pink.opacity(0.5))
            Text("No Lyrics Yet").font(.title2.weight(.semibold))
            Text("Tap + to create your first lyric pad.").foregroundStyle(.secondary)
            Button("New Lyric") { createEntry() }
                .buttonStyle(.borderedProminent).tint(.pink)
        }
    }

    private var entryList: some View {
        List {
            ForEach(entries) { entry in
                Button { selectedEntry = entry } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title).fontWeight(.semibold).foregroundStyle(.primary)
                        Text("\(entry.lineCount) lines · \(entry.wordCount) words")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(entry.dateModified, style: .relative)
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            .onDelete(perform: deleteEntries)
        }
        .listStyle(.insetGrouped)
    }

    private func createEntry() {
        let e = LyricEntry(title: "Untitled \(entries.count + 1)")
        ctx.insert(e)
        selectedEntry = e
    }

    private func deleteEntries(at offsets: IndexSet) {
        for i in offsets { ctx.delete(entries[i]) }
    }
}

struct LyricEditorView: View {
    @Bindable var entry: LyricEntry
    @State private var engine = RhymeEngine()
    @State private var rhymeSuggestions: [String] = []
    @State private var currentLineEndWord = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TextField("Title", text: $entry.title)
                .font(.title2.weight(.bold))
                .padding(.horizontal)
                .padding(.top, 8)

            Divider().padding(.vertical, 4)

            TextEditor(text: $entry.content)
                .font(.body)
                .padding(.horizontal, 8)
                .focused($focused)
                .onChange(of: entry.content) { _, new in
                    entry.dateModified = Date()
                    updateRhymeSuggestions(text: new)
                }

            if !rhymeSuggestions.isEmpty {
                rhymeBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: "\(entry.title)\n\n\(entry.content)")
            }
        }
        .onAppear { focused = true }
    }

    private var rhymeBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Image(systemName: "music.note").foregroundStyle(.pink).font(.caption)
                Text("Rhymes for \u{201C}\(currentLineEndWord)\u{201D}:")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(rhymeSuggestions, id: \.self) { word in
                    Button {
                        insertWord(word)
                    } label: {
                        Text(word)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.pink.opacity(0.15), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGray6))
    }

    private func updateRhymeSuggestions(text: String) {
        let lines = text.components(separatedBy: "\n")
        guard let lastLine = lines.last(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) else {
            rhymeSuggestions = []; currentLineEndWord = ""; return
        }
        let words = lastLine.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard let lastWord = words.last else {
            rhymeSuggestions = []; currentLineEndWord = ""; return
        }
        let clean = lastWord.lowercased().trimmingCharacters(in: .punctuationCharacters)
        if clean == currentLineEndWord { return }
        currentLineEndWord = clean
        rhymeSuggestions = engine.quickSuggest(for: clean)
    }

    private func insertWord(_ word: String) {
        entry.content += word + "\n"
        entry.dateModified = Date()
    }
}
