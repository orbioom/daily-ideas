import SwiftUI
import SwiftData

struct TagsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Tag.name) private var tags: [Tag]
    @Query private var notes: [Note]
    @State private var path = NavigationPath()
    @State private var renaming: Tag?

    private func count(_ tag: Tag) -> Int {
        notes.filter { n in !n.isArchived && n.tags.contains { $0.persistentModelID == tag.persistentModelID } }.count
    }
    private var sortedByUse: [Tag] { tags.sorted { count($0) > count($1) } }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if tags.isEmpty {
                    EmptyState(icon: "number",
                               title: "No tags yet",
                               message: "Add tags to a note from its details panel, then browse them here.")
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionHeader(text: "Tag cloud")
                                FlowLayout(spacing: 8) {
                                    ForEach(sortedByUse) { tag in
                                        Button { path.append(tag) } label: {
                                            HStack(spacing: 5) {
                                                Text("#\(tag.name)")
                                                    .font(.system(size: CGFloat(13 + min(count(tag), 8)),
                                                                  weight: .medium, design: .rounded))
                                                Text("\(count(tag))")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundStyle(.white)
                                                    .padding(.horizontal, 6).padding(.vertical, 1)
                                                    .background(Capsule().fill(Theme.accent))
                                            }
                                            .foregroundStyle(Theme.accent)
                                            .padding(.horizontal, 12).padding(.vertical, 7)
                                            .background(Capsule().fill(Theme.accentSoft))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.horizontal, 18)

                            VStack(spacing: 0) {
                                ForEach(sortedByUse) { tag in
                                    Button { path.append(tag) } label: {
                                        HStack {
                                            Text("#\(tag.name)")
                                                .font(.system(size: 16))
                                                .foregroundStyle(Theme.ink)
                                            Spacer()
                                            Text("\(count(tag))")
                                                .font(.system(size: 15)).monospacedDigit()
                                                .foregroundStyle(Theme.inkFaint)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12)).foregroundStyle(Theme.inkFaint)
                                        }
                                        .padding(.vertical, 13).padding(.horizontal, 16)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button { renaming = tag } label: { Label("Rename", systemImage: "pencil") }
                                        Button(role: .destructive) { context.delete(tag) } label: {
                                            Label("Delete tag", systemImage: "trash")
                                        }
                                    }
                                    if tag.persistentModelID != sortedByUse.last?.persistentModelID {
                                        Divider().background(Theme.hairline).padding(.leading, 16)
                                    }
                                }
                            }
                            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
                            .padding(.horizontal, 18)
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationDestination(for: Tag.self) { tag in
                TagNotesView(tag: tag, path: $path)
            }
            .navigationDestination(for: Note.self) { note in
                NoteDetailView(note: note, path: $path)
            }
            .alert("Rename tag", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
                TagRenameField(tag: renaming)
            }
        }
    }
}

private struct TagRenameField: View {
    let tag: Tag?
    @State private var name = ""
    var body: some View {
        TextField("Tag name", text: $name)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .onAppear { name = tag?.name ?? "" }
        Button("Cancel", role: .cancel) {}
        Button("Save") {
            let cleaned = name.trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "#", with: "").lowercased()
            if let tag, !cleaned.isEmpty { tag.name = cleaned }
        }
    }
}

struct TagNotesView: View {
    let tag: Tag
    @Binding var path: NavigationPath
    @Query private var notes: [Note]

    private var matching: [Note] {
        notes.filter { n in !n.isArchived && n.tags.contains { $0.persistentModelID == tag.persistentModelID } }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if matching.isEmpty {
                EmptyState(icon: "number", title: "No notes",
                           message: "No notes use #\(tag.name) right now.")
            } else {
                List {
                    ForEach(matching) { note in
                        NavigationLink(value: note) { NoteRow(note: note) }
                            .listRowBackground(Theme.bg)
                            .listRowSeparatorTint(Theme.hairline)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("#\(tag.name)")
        .navigationBarTitleDisplayMode(.large)
    }
}
