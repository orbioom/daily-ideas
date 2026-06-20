import Foundation

enum FountainElementType: Equatable {
    case titlePage
    case sceneHeading
    case action
    case character
    case dialogue
    case parenthetical
    case transition
    case centered
    case pageBreak
    case empty
}

struct FountainElement {
    let type: FountainElementType
    let text: String
}

struct FountainParser {

    static func parse(text: String) -> [FountainElement] {
        let lines = text.components(separatedBy: "\n")
        var elements: [FountainElement] = []
        var prevType: FountainElementType = .empty

        var i = 0
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                elements.append(FountainElement(type: .empty, text: ""))
                prevType = .empty
                i += 1
                continue
            }

            // Page break
            if trimmed == "===" || trimmed.hasPrefix("===") {
                elements.append(FountainElement(type: .pageBreak, text: ""))
                prevType = .pageBreak
                i += 1
                continue
            }

            // Centered text: >text<
            if trimmed.hasPrefix(">") && trimmed.hasSuffix("<") {
                let inner = String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
                elements.append(FountainElement(type: .centered, text: inner))
                prevType = .centered
                i += 1
                continue
            }

            // Transition: ends with " TO:" or is "FADE OUT." / "FADE IN:"
            if isTransition(trimmed) {
                elements.append(FountainElement(type: .transition, text: trimmed))
                prevType = .transition
                i += 1
                continue
            }

            // Scene heading: starts with INT., EXT., INT/EXT., I/E
            if isSceneHeading(trimmed) {
                elements.append(FountainElement(type: .sceneHeading, text: trimmed.uppercased()))
                prevType = .sceneHeading
                i += 1
                continue
            }

            // Parenthetical: starts with ( and ends with )
            if trimmed.hasPrefix("(") && trimmed.hasSuffix(")") &&
               (prevType == .character || prevType == .dialogue || prevType == .parenthetical) {
                elements.append(FountainElement(type: .parenthetical, text: trimmed))
                prevType = .parenthetical
                i += 1
                continue
            }

            // Character: ALL CAPS, alone on line, after blank/transition/action
            if isCharacterName(trimmed, prevType: prevType) {
                elements.append(FountainElement(type: .character, text: trimmed))
                prevType = .character
                i += 1
                continue
            }

            // Dialogue: after character or parenthetical
            if prevType == .character || prevType == .parenthetical {
                elements.append(FountainElement(type: .dialogue, text: trimmed))
                prevType = .dialogue
                i += 1
                continue
            }

            // Default: action
            elements.append(FountainElement(type: .action, text: trimmed))
            prevType = .action
            i += 1
        }

        return elements.filter { $0.type != .empty }
    }

    static func estimatePageCount(elements: [FountainElement]) -> Int {
        var lines = 0
        for element in elements {
            switch element.type {
            case .sceneHeading: lines += 2
            case .action:
                let wordCount = element.text.split(separator: " ").count
                lines += max(1, wordCount / 10)
            case .character: lines += 1
            case .dialogue:
                let wordCount = element.text.split(separator: " ").count
                lines += max(1, wordCount / 7)
            case .parenthetical: lines += 1
            case .transition: lines += 2
            default: lines += 1
            }
        }
        return max(1, lines / 55)
    }

    // MARK: - Helpers

    private static func isSceneHeading(_ line: String) -> Bool {
        let upper = line.uppercased()
        return upper.hasPrefix("INT.") || upper.hasPrefix("EXT.") ||
               upper.hasPrefix("INT/EXT") || upper.hasPrefix("I/E") ||
               (line.hasPrefix(".") && line.count > 1)
    }

    private static func isTransition(_ line: String) -> Bool {
        let upper = line.uppercased()
        if upper == "FADE OUT." || upper == "FADE IN:" { return true }
        if upper.hasSuffix(" TO:") || upper.hasSuffix("TO:") { return true }
        if line.hasPrefix(">") && !line.hasSuffix("<") { return true }
        return false
    }

    private static func isCharacterName(_ line: String, prevType: FountainElementType) -> Bool {
        guard prevType == .empty || prevType == .action || prevType == .transition || prevType == .sceneHeading else { return false }
        let upper = line.uppercased()
        if line != upper { return false }
        if line.hasSuffix(":") { return false }
        if line.contains(".") && !line.hasSuffix("(") { return false }
        return line.count >= 1 && line.count <= 60
    }
}
