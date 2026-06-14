import SwiftUI
import SwiftData

/// Pushed detail screen for a single node: large text editor, note field,
/// breadcrumb path from root, child count, and a color picker.
struct NodeDetailView: View {
    @Bindable var node: MapNode
    let editor: MapEditor
    @Environment(\.dismiss) private var dismiss

    @State private var text: String = ""
    @State private var note: String = ""
    @State private var saved = false
    @FocusState private var noteFocused: Bool

    private var breadcrumb: [MapNode] {
        var chain: [MapNode] = []
        var cur: MapNode? = node
        while let c = cur {
            chain.append(c)
            cur = c.parent
        }
        return chain.reversed()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                breadcrumbView

                CardSection {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Text")
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                        TextField("Node text", text: $text, axis: .vertical)
                            .font(Theme.rounded(22, .bold))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1...4)
                    }
                }

                CardSection {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Note")
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                        TextEditor(text: $note)
                            .font(Theme.rounded(16))
                            .foregroundStyle(Theme.ink)
                            .frame(minHeight: 140)
                            .scrollContentBackground(.hidden)
                            .focused($noteFocused)
                            .overlay(alignment: .topLeading) {
                                if note.isEmpty && !noteFocused {
                                    Text("Add a longer note for this idea\u{2026}")
                                        .font(Theme.rounded(16))
                                        .foregroundStyle(Theme.inkFaint)
                                        .padding(.top, 8)
                                        .allowsHitTesting(false)
                                }
                            }
                    }
                }

                colorRow
                metaRow

                saveButton
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Node")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            text = node.text
            note = node.note
        }
    }

    private var breadcrumbView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(breadcrumb.enumerated()), id: \.element.id) { idx, n in
                    if idx > 0 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.inkFaint)
                    }
                    Text(n.text.isEmpty ? "Untitled" : n.text)
                        .font(Theme.rounded(12, n.id == node.id ? .bold : .medium))
                        .foregroundStyle(n.id == node.id ? Theme.accent : Theme.inkSoft)
                        .lineLimit(1)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Path: " + breadcrumb.map { $0.text.isEmpty ? "Untitled" : $0.text }.joined(separator: ", "))
    }

    private var colorRow: some View {
        CardSection {
            VStack(alignment: .leading, spacing: 12) {
                Text("Color")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                HStack(spacing: 14) {
                    ForEach(NodePalette.allCases) { p in
                        Button {
                            editor.setColor(p.rawValue, on: node)
                            Haptics.selection()
                        } label: {
                            ColorDot(palette: p, selected: node.colorTag == p.rawValue, diameter: 30)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(p.name)
                    }
                }
            }
        }
    }

    private var metaRow: some View {
        CardSection {
            HStack {
                Label("\(node.children.count) direct children", systemImage: "circle.hexagongrid")
                Spacer()
                Label("Depth \(node.depth)", systemImage: "arrow.down.right")
            }
            .font(Theme.rounded(13))
            .foregroundStyle(Theme.inkSoft)
        }
    }

    private var saveButton: some View {
        Button {
            editor.setText(text.trimmingCharacters(in: .whitespacesAndNewlines), on: node)
            editor.setNote(note, on: node)
            Haptics.success()
            withAnimation { saved = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { saved = false }
        } label: {
            HStack {
                Image(systemName: saved ? "checkmark.circle.fill" : "square.and.arrow.down")
                Text(saved ? "Saved" : "Save changes")
            }
            .font(Theme.rounded(16, .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(saved ? Theme.good : Theme.accent,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .accessibilityLabel(saved ? "Saved" : "Save changes")
    }
}
