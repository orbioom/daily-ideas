import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Builds an indented Markdown outline string from a map's tree, and wraps it in a
/// `Transferable` document so it can be used with `ShareLink`.
enum OutlineExport {

    /// Render the whole map as a Markdown document.
    static func markdown(for map: MindMap) -> String {
        var lines: [String] = []
        let title = map.title.isEmpty ? "Untitled Map" : map.title
        lines.append("# \(title)")
        lines.append("")

        if let root = map.root {
            // The root becomes a top-level heading line; its children are bullets.
            appendNode(root, indent: 0, into: &lines, isRoot: true)
        } else {
            lines.append("_This map has no nodes yet._")
        }

        lines.append("")
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        lines.append("_Exported from Aster on \(fmt.string(from: Date()))_")
        return lines.joined(separator: "\n")
    }

    private static func appendNode(_ node: MapNode,
                                   indent: Int,
                                   into lines: inout [String],
                                   isRoot: Bool) {
        let text = node.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let shown = text.isEmpty ? "(untitled)" : text

        if isRoot {
            lines.append("## \(shown)")
            if !node.note.isEmpty {
                lines.append("")
                lines.append(node.note)
            }
            lines.append("")
        } else {
            let pad = String(repeating: "  ", count: max(0, indent - 1))
            lines.append("\(pad)- \(shown)")
            if !node.note.isEmpty {
                let notePad = String(repeating: "  ", count: max(0, indent))
                lines.append("\(notePad)> \(node.note)")
            }
        }

        for child in node.sortedChildren {
            appendNode(child, indent: indent + 1, into: &lines, isRoot: false)
        }
    }

    /// A transferable text document for `ShareLink`.
    static func document(for map: MindMap) -> OutlineDocument {
        OutlineDocument(text: markdown(for: map),
                        name: (map.title.isEmpty ? "Aster Map" : map.title))
    }
}

/// Plain-text/Markdown document that `ShareLink` can export as a file.
struct OutlineDocument: Transferable {
    let text: String
    let name: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .plainText) { doc in
            Data(doc.text.utf8)
        }
        .suggestedFileName { "\($0.name).md" }

        ProxyRepresentation { $0.text } // allows copy/paste as a string too
    }
}
