import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Bindable var note: Note
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var mode: Mode = .write
    @State private var showDetails = false
    @FocusState private var bodyFocused: Bool

    enum Mode: String, CaseIterable { case write = "Write", preview = "Preview" }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 4)

                    if mode == .write {
                        writeMode
                    } else {
                        previewMode
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { save(); dismiss() }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showDetails = true } label: { Image(systemName: "slider.horizontal.3") }
                        .accessibilityLabel("Note details")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    formatButton("number", block: "## ")
                    formatButton("bold", inline: "**bold**")
                    formatButton("list.bullet", block: "- ")
                    formatButton("checklist", block: "- [ ] ")
                    formatButton("link", inline: "[[note]]")
                    Spacer()
                    Button("Done") { bodyFocused = false }
                }
            }
            .sheet(isPresented: $showDetails) {
                NoteDetailsSheet(note: note)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var writeMode: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Title", text: $note.title, axis: .vertical)
                .font(Theme.serifTitle(26))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 18).padding(.top, 10).padding(.bottom, 4)
                .submitLabel(.next)

            TextEditor(text: $note.body)
                .font(Theme.serif(17))
                .foregroundStyle(Theme.ink)
                .scrollContentBackground(.hidden)
                .background(Theme.bg)
                .padding(.horizontal, 14)
                .focused($bodyFocused)
                .overlay(alignment: .topLeading) {
                    if note.body.isEmpty {
                        Text("Start writing in Markdown…")
                            .font(Theme.serif(17))
                            .foregroundStyle(Theme.inkFaint)
                            .padding(.horizontal, 19).padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }

            footer
        }
    }

    private var previewMode: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(note.displayTitle)
                    .font(Theme.serifTitle(28))
                    .foregroundStyle(Theme.ink)
                if note.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Nothing to preview yet.")
                        .font(.system(size: 15)).italic()
                        .foregroundStyle(Theme.inkFaint)
                } else {
                    MarkdownView(source: note.body)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var footer: some View {
        HStack {
            ColorDot(index: note.colorIndex, size: 10)
            if let folder = note.folder {
                Label(folder.name, systemImage: folder.symbol)
            }
            Spacer()
            Text("\(note.wordCount) words")
        }
        .font(.system(size: 12))
        .foregroundStyle(Theme.inkFaint)
        .labelStyle(.titleAndIcon)
        .padding(.horizontal, 18).padding(.vertical, 10)
        .background(Theme.surface)
    }

    /// `block` snippets start on a fresh line; `inline` snippets insert in place.
    private func formatButton(_ icon: String, block: String? = nil, inline: String? = nil) -> some View {
        Button {
            if let block {
                if note.body.isEmpty || note.body.hasSuffix("\n") {
                    note.body += block
                } else {
                    note.body += "\n" + block
                }
            } else if let inline {
                note.body += inline
            }
            Haptics.tap()
        } label: { Image(systemName: icon) }
    }

    private func save() {
        note.updatedAt = .now
        if note.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           note.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Discard a completely empty note rather than littering the library.
            context.delete(note)
        }
        try? context.save()
    }
}

struct NoteDetailsSheet: View {
    @Bindable var note: Note
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]
    @Query(sort: \Tag.name) private var allTags: [Tag]
    @State private var newTag = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Folder") {
                    Picker("Folder", selection: folderBinding) {
                        Text("None").tag(Optional<Folder>.none)
                        ForEach(folders) { f in
                            Label(f.name, systemImage: f.symbol).tag(Optional(f))
                        }
                    }
                }
                Section("Accent") {
                    HStack(spacing: 14) {
                        ForEach(Theme.tagColors.indices, id: \.self) { i in
                            Button { note.colorIndex = i; Haptics.tap() } label: {
                                ColorDot(index: i, size: 26)
                                    .overlay {
                                        if note.colorIndex == i {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(i == 0 ? Theme.ink : .white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Theme.tagColors[i].name)
                        }
                    }
                    .padding(.vertical, 2)
                }
                Section("Tags") {
                    if !note.tags.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(note.tags.sorted { $0.name < $1.name }) { tag in
                                Button { remove(tag); Haptics.tap() } label: {
                                    HStack(spacing: 4) {
                                        Text("#\(tag.name)")
                                        Image(systemName: "xmark.circle.fill").font(.system(size: 12))
                                    }
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(Theme.accent)
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(Capsule().fill(Theme.accentSoft))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    HStack {
                        TextField("Add tag", text: $newTag)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onSubmit(addTag)
                        Button("Add", action: addTag).disabled(cleanedTag.isEmpty)
                    }
                    let suggestions = allTags.filter { t in !note.tags.contains(where: { $0.name == t.name }) }
                    if !suggestions.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(suggestions) { tag in
                                Button { note.tags.append(tag); Haptics.tap() } label: { TagChip(text: tag.name) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                }
                Section {
                    Toggle("Pinned", isOn: $note.isPinned)
                    Button(note.isArchived ? "Unarchive" : "Archive") {
                        note.isArchived.toggle(); note.updatedAt = .now; dismiss()
                    }
                    Button("Delete note", role: .destructive) {
                        context.delete(note); dismiss()
                    }
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }

    private var folderBinding: Binding<Folder?> {
        Binding(get: { note.folder }, set: { note.folder = $0; note.updatedAt = .now })
    }

    private var cleanedTag: String {
        newTag.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "#", with: "").lowercased()
    }

    private func addTag() {
        let name = cleanedTag
        guard !name.isEmpty else { return }
        if note.tags.contains(where: { $0.name == name }) { newTag = ""; return }
        if let existing = allTags.first(where: { $0.name == name }) {
            note.tags.append(existing)
        } else {
            let tag = Tag(name: name)
            context.insert(tag)
            note.tags.append(tag)
        }
        note.updatedAt = .now
        newTag = ""
        Haptics.tap()
    }

    private func remove(_ tag: Tag) {
        note.tags.removeAll { $0.persistentModelID == tag.persistentModelID }
        note.updatedAt = .now
    }
}
