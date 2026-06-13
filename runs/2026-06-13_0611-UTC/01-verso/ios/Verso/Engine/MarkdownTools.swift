import Foundation
import SwiftUI

/// Lightweight block + inline Markdown handling tuned for Verso.
/// Pure value logic — no external dependencies.
enum MarkdownBlock: Identifiable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case bullet(text: String, indent: Int)
    case numbered(number: Int, text: String)
    case todo(checked: Bool, text: String)
    case quote(String)
    case code(String)
    case divider

    var id: String {
        switch self {
        case .heading(let l, let t): return "h\(l)-\(t.hashValue)"
        case .paragraph(let t): return "p-\(t.hashValue)"
        case .bullet(let t, let i): return "b\(i)-\(t.hashValue)"
        case .numbered(let n, let t): return "n\(n)-\(t.hashValue)"
        case .todo(let c, let t): return "t\(c)-\(t.hashValue)"
        case .quote(let t): return "q-\(t.hashValue)"
        case .code(let t): return "c-\(t.hashValue)"
        case .divider: return "divider-\(UUID().uuidString)"
        }
    }
}

enum MarkdownTools {

    // MARK: Block parsing

    static func parse(_ source: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = source.components(separatedBy: "\n")
        var paragraph: [String] = []
        var inCode = false
        var code: [String] = []

        func flushParagraph() {
            let joined = paragraph.joined(separator: " ").trimmingCharacters(in: .whitespaces)
            if !joined.isEmpty { blocks.append(.paragraph(joined)) }
            paragraph.removeAll()
        }

        for raw in lines {
            let line = raw

            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                if inCode {
                    blocks.append(.code(code.joined(separator: "\n")))
                    code.removeAll(); inCode = false
                } else {
                    flushParagraph(); inCode = true
                }
                continue
            }
            if inCode { code.append(line); continue }

            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty { flushParagraph(); continue }

            // divider
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                flushParagraph(); blocks.append(.divider); continue
            }
            // heading
            if let h = headingLevel(trimmed) {
                flushParagraph()
                let text = String(trimmed.drop(while: { $0 == "#" })).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(level: h, text: text)); continue
            }
            // todo
            if let (checked, rest) = todoItem(trimmed) {
                flushParagraph()
                blocks.append(.todo(checked: checked, text: rest)); continue
            }
            // quote
            if trimmed.hasPrefix("> ") || trimmed == ">" {
                flushParagraph()
                blocks.append(.quote(String(trimmed.dropFirst(1)).trimmingCharacters(in: .whitespaces)))
                continue
            }
            // bullet
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                flushParagraph()
                let indent = leadingSpaces(line) / 2
                blocks.append(.bullet(text: String(trimmed.dropFirst(2)), indent: indent)); continue
            }
            // numbered
            if let (num, rest) = numberedItem(trimmed) {
                flushParagraph()
                blocks.append(.numbered(number: num, text: rest)); continue
            }
            // paragraph accumulation
            paragraph.append(trimmed)
        }
        if inCode && !code.isEmpty { blocks.append(.code(code.joined(separator: "\n"))) }
        flushParagraph()
        return blocks
    }

    private static func headingLevel(_ s: String) -> Int? {
        var count = 0
        for c in s { if c == "#" { count += 1 } else { break } }
        guard count >= 1, count <= 6 else { return nil }
        let after = s.dropFirst(count)
        return after.first == " " ? count : nil
    }

    private static func todoItem(_ s: String) -> (Bool, String)? {
        let lower = s.lowercased()
        if lower.hasPrefix("- [ ]") { return (false, String(s.dropFirst(5)).trimmingCharacters(in: .whitespaces)) }
        if lower.hasPrefix("- [x]") { return (true, String(s.dropFirst(5)).trimmingCharacters(in: .whitespaces)) }
        return nil
    }

    private static func numberedItem(_ s: String) -> (Int, String)? {
        var digits = ""
        var idx = s.startIndex
        while idx < s.endIndex, s[idx].isNumber { digits.append(s[idx]); idx = s.index(after: idx) }
        guard !digits.isEmpty, idx < s.endIndex, s[idx] == "." else { return nil }
        let after = s.index(after: idx)
        guard after < s.endIndex, s[after] == " " else { return nil }
        let rest = String(s[s.index(after: after)...])
        return (Int(digits) ?? 1, rest)
    }

    private static func leadingSpaces(_ s: String) -> Int {
        var n = 0
        for c in s { if c == " " { n += 1 } else if c == "\t" { n += 2 } else { break } }
        return n
    }

    // MARK: Inline rendering

    /// Convert inline markdown (with [[wiki links]]) into an AttributedString.
    static func inline(_ text: String) -> AttributedString {
        let converted = convertWikiLinks(text)
        if let attr = try? AttributedString(
            markdown: converted,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace,
                           failurePolicy: .returnPartiallyParsedIfPossible)) {
            return attr
        }
        return AttributedString(stripInline(text))
    }

    /// Replace [[Title]] with a tappable link to verso://note/<encoded>.
    static func convertWikiLinks(_ text: String) -> String {
        guard text.contains("[[") else { return text }
        var result = ""
        var rest = Substring(text)
        while let open = rest.range(of: "[[") {
            result += rest[..<open.lowerBound]
            let afterOpen = rest[open.upperBound...]
            if let close = afterOpen.range(of: "]]") {
                let title = String(afterOpen[..<close.lowerBound])
                let enc = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title
                result += "[\(title)](verso://note/\(enc))"
                rest = afterOpen[close.upperBound...]
            } else {
                result += "[["
                rest = afterOpen
            }
        }
        result += rest
        return result
    }

    /// Names referenced via [[wiki links]] in the source.
    static func wikiLinkTitles(_ text: String) -> [String] {
        var titles: [String] = []
        var rest = Substring(text)
        while let open = rest.range(of: "[[") {
            let afterOpen = rest[open.upperBound...]
            if let close = afterOpen.range(of: "]]") {
                let t = String(afterOpen[..<close.lowerBound]).trimmingCharacters(in: .whitespaces)
                if !t.isEmpty { titles.append(t) }
                rest = afterOpen[close.upperBound...]
            } else { break }
        }
        return titles
    }

    /// Strip common inline syntax for plain-text previews.
    static func stripInline(_ s: String) -> String {
        var out = s
        let patterns = ["**", "__", "`", "~~"]
        for p in patterns { out = out.replacingOccurrences(of: p, with: "") }
        out = out.replacingOccurrences(of: "[[", with: "")
        out = out.replacingOccurrences(of: "]]", with: "")
        // leading markers
        while out.hasPrefix("#") { out.removeFirst() }
        for prefix in ["> ", "- [ ] ", "- [x] ", "- ", "* ", "+ "] {
            if out.hasPrefix(prefix) { out = String(out.dropFirst(prefix.count)); break }
        }
        return out.trimmingCharacters(in: .whitespaces)
    }
}
