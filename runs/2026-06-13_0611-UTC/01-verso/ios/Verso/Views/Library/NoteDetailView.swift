import SwiftUI
import SwiftData

struct NoteDetailView: View {
    @Bindable var note: Note
    @Binding var path: NavigationPath

    @Environment(\.modelContext) private var context
    @Query private var allNotes: [Note]
    @State private var editing = false

    private var backlinks: [Note] {
        let target = note.displayTitle.lowercased()
        guard !target.isEmpty else { return [] }
        return allNotes.filter { other in
            other.persistentModelID != note.persistentModelID &&
            MarkdownTools.wikiLinkTitles(other.body).contains { $0.lowercased() == target }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(note.displayTitle)
                    .font(Theme.serifTitle(30))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                metadata

                if !note.tags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(note.tags.sorted { $0.name < $1.name }) { TagChip(text: $0.name) }
                    }
                }

                Divider().background(Theme.hairline)

                if note.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("This note has no body yet. Tap Edit to start writing.")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.inkFaint)
                        .italic()
                        .padding(.vertical, 8)
                } else {
                    MarkdownView(source: note.body)
                }

                if !backlinks.isEmpty {
                    backlinksSection
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Theme.accent)
        .environment(\.openURL, OpenURLAction { url in
            handleWikiLink(url)
        })
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { note.isPinned.toggle(); note.updatedAt = .now; Haptics.tap() } label: {
                    Image(systemName: note.isPinned ? "pin.fill" : "pin")
                }
                .accessibilityLabel(note.isPinned ? "Unpin note" : "Pin note")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { editing = true }
            }
        }
        .sheet(isPresented: $editing) { NoteEditorView(note: note) }
    }

    private var metadata: some View {
        HStack(spacing: 12) {
            if let folder = note.folder {
                Label(folder.name, systemImage: folder.symbol)
            }
            Label("\(note.wordCount) words", systemImage: "textformat.size")
            Text(note.updatedAt, format: .dateTime.month().day().year())
        }
        .font(.system(size: 12))
        .foregroundStyle(Theme.inkFaint)
        .labelStyle(.titleAndIcon)
    }

    private var backlinksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider().background(Theme.hairline).padding(.top, 8)
            Label("Linked from \(backlinks.count) note\(backlinks.count == 1 ? "" : "s")",
                  systemImage: "arrow.turn.down.left")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.accent)
            ForEach(backlinks) { other in
                Button { path.append(other) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(other.displayTitle)
                                .font(.system(size: 15, weight: .semibold, design: .serif))
                                .foregroundStyle(Theme.ink)
                            if !other.snippet.isEmpty {
                                Text(other.snippet)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.inkSoft)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Theme.inkFaint)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
                }
            }
        }
    }

    private func handleWikiLink(_ url: URL) -> OpenURLAction.Result {
        guard url.scheme == "verso", url.host == "note" else { return .systemAction }
        let raw = url.pathComponents.dropFirst().joined(separator: "/")
        let title = raw.removingPercentEncoding ?? raw
        let lowered = title.lowercased()
        if let match = allNotes.first(where: { $0.displayTitle.lowercased() == lowered && !$0.isArchived }) {
            Haptics.tap()
            path.append(match)
            return .handled
        }
        // No note with that title yet — offer to create it.
        let created = Note(title: title, body: "")
        context.insert(created)
        Haptics.success()
        path.append(created)
        return .handled
    }
}

/// Renders parsed Markdown blocks in Verso's editorial style.
struct MarkdownView: View {
    let source: String
    private var blocks: [MarkdownBlock] { MarkdownTools.parse(source) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(blocks) { block in
                blockView(block)
            }
        }
        .tint(Theme.accent)
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            Text(MarkdownTools.inline(text))
                .font(Theme.serifTitle(headingSize(level)))
                .foregroundStyle(Theme.ink)
                .padding(.top, level <= 2 ? 6 : 2)
        case .paragraph(let text):
            Text(MarkdownTools.inline(text))
                .font(Theme.serif(17))
                .foregroundStyle(Theme.ink)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        case .bullet(let text, let indent):
            HStack(alignment: .top, spacing: 8) {
                Text("•").foregroundStyle(Theme.accent).font(.system(size: 17))
                Text(MarkdownTools.inline(text)).font(Theme.serif(17)).foregroundStyle(Theme.ink)
            }
            .padding(.leading, CGFloat(indent) * 16)
        case .numbered(let number, let text):
            HStack(alignment: .top, spacing: 8) {
                Text("\(number).").foregroundStyle(Theme.accent).font(.system(size: 16, weight: .semibold))
                    .monospacedDigit()
                Text(MarkdownTools.inline(text)).font(Theme.serif(17)).foregroundStyle(Theme.ink)
            }
        case .todo(let checked, let text):
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: checked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(checked ? Theme.accent : Theme.inkFaint)
                    .font(.system(size: 17))
                Text(MarkdownTools.inline(text))
                    .font(Theme.serif(17))
                    .foregroundStyle(checked ? Theme.inkFaint : Theme.ink)
                    .strikethrough(checked, color: Theme.inkFaint)
            }
        case .quote(let text):
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2).fill(Theme.accent).frame(width: 3)
                Text(MarkdownTools.inline(text))
                    .font(.system(size: 17, design: .serif)).italic()
                    .foregroundStyle(Theme.inkSoft)
            }
            .fixedSize(horizontal: false, vertical: true)
        case .code(let text):
            Text(text)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(Theme.ink)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceAlt))
        case .divider:
            Divider().background(Theme.hairline).padding(.vertical, 4)
        }
    }

    private func headingSize(_ level: Int) -> CGFloat {
        switch level {
        case 1: return 26
        case 2: return 22
        case 3: return 19
        default: return 17
        }
    }
}
