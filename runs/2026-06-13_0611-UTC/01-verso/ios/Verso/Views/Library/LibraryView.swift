import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Note.updatedAt, order: .reverse) private var allNotes: [Note]

    @AppStorage("defaultSort") private var defaultSort = SortMode.updated.rawValue
    @State private var path = NavigationPath()
    @State private var search = ""
    @State private var sort: SortMode = .updated
    @State private var editingNote: Note?
    @State private var didLoadSort = false

    enum SortMode: String, CaseIterable, Identifiable {
        case updated = "Last edited", created = "Date created", title = "Title", words = "Length"
        var id: String { rawValue }
    }

    private var active: [Note] { allNotes.filter { !$0.isArchived } }

    private var filtered: [Note] {
        let base: [Note]
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty {
            base = active
        } else {
            base = active.filter {
                $0.title.lowercased().contains(q) ||
                $0.body.lowercased().contains(q) ||
                $0.tags.contains { $0.name.lowercased().contains(q) }
            }
        }
        switch sort {
        case .updated: return base.sorted { $0.updatedAt > $1.updatedAt }
        case .created: return base.sorted { $0.createdAt > $1.createdAt }
        case .title:   return base.sorted { $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending }
        case .words:   return base.sorted { $0.wordCount > $1.wordCount }
        }
    }

    private var pinned: [Note] { filtered.filter { $0.isPinned } }
    private var others: [Note] { filtered.filter { !$0.isPinned } }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if active.isEmpty {
                    EmptyState(icon: "note.text",
                               title: "A blank page",
                               message: "Your notes will live here. Tap the pencil to write your first one.",
                               actionTitle: "New note") { newNote() }
                } else if filtered.isEmpty {
                    EmptyState(icon: "magnifyingglass",
                               title: "No matches",
                               message: "No notes contain “\(search)”. Try a different word.")
                } else {
                    List {
                        if !pinned.isEmpty {
                            Section {
                                ForEach(pinned) { row($0) }
                            } header: { SectionHeader(text: "Pinned") }
                        }
                        Section {
                            ForEach(others) { row($0) }
                        } header: {
                            SectionHeader(text: pinned.isEmpty ? "All notes" : "Notes")
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Verso")
            .navigationDestination(for: Note.self) { note in
                NoteDetailView(note: note, path: $path)
            }
            .onAppear {
                if !didLoadSort {
                    sort = SortMode(rawValue: defaultSort) ?? .updated
                    didLoadSort = true
                }
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search notes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort", selection: $sort) {
                            ForEach(SortMode.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { newNote() } label: { Image(systemName: "square.and.pencil") }
                        .accessibilityLabel("New note")
                }
            }
            .sheet(item: $editingNote) { note in
                NoteEditorView(note: note)
            }
        }
    }

    @ViewBuilder
    private func row(_ note: Note) -> some View {
        NavigationLink(value: note) {
            NoteRow(note: note)
        }
        .listRowBackground(Theme.bg)
        .listRowSeparatorTint(Theme.hairline)
        .swipeActions(edge: .leading) {
            Button {
                note.isPinned.toggle(); note.updatedAt = .now; Haptics.tap()
            } label: {
                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
            }
            .tint(Theme.amber)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                context.delete(note); Haptics.warning()
            } label: { Label("Delete", systemImage: "trash") }
            Button {
                note.isArchived = true; note.updatedAt = .now; Haptics.tap()
            } label: { Label("Archive", systemImage: "archivebox") }
            .tint(Theme.inkFaint)
        }
    }

    private func newNote() {
        let note = Note(title: "", body: "")
        context.insert(note)
        Haptics.tap()
        editingNote = note
    }
}

struct NoteRow: View {
    let note: Note
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.tagColor(note.colorIndex))
                .frame(width: 4)
                .frame(maxHeight: .infinity)
                .opacity(note.colorIndex == 0 ? 0.0 : 1.0)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.amber)
                            .accessibilityHidden(true)
                    }
                    Text(note.displayTitle)
                        .font(Theme.serifTitle(18))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                }
                if !note.snippet.isEmpty {
                    Text(note.snippet)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(2)
                }
                HStack(spacing: 8) {
                    Text(note.updatedAt, format: .relative(presentation: .named))
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkFaint)
                    if let folder = note.folder {
                        Label(folder.name, systemImage: folder.symbol)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkFaint)
                            .labelStyle(.titleAndIcon)
                    }
                    if !note.tags.isEmpty {
                        Text("#\(note.tags.first!.name)\(note.tags.count > 1 ? " +\(note.tags.count - 1)" : "")")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [note.displayTitle]
        if !note.snippet.isEmpty { parts.append(note.snippet) }
        if note.isPinned { parts.append("Pinned") }
        if let f = note.folder { parts.append("in \(f.name)") }
        return parts.joined(separator: ", ")
    }
}
