import Foundation

/// The eight typing fingers (thumbs handle the space bar together).
enum Finger: String, CaseIterable, Identifiable {
    case leftPinky, leftRing, leftMiddle, leftIndex
    case rightIndex, rightMiddle, rightRing, rightPinky
    case thumb

    var id: String { rawValue }

    var label: String {
        switch self {
        case .leftPinky: return "Left pinky"
        case .leftRing: return "Left ring"
        case .leftMiddle: return "Left middle"
        case .leftIndex: return "Left index"
        case .rightIndex: return "Right index"
        case .rightMiddle: return "Right middle"
        case .rightRing: return "Right ring"
        case .rightPinky: return "Right pinky"
        case .thumb: return "Thumb"
        }
    }
}

/// Maps a character to the finger that should press it on a standard QWERTY layout.
enum FingerMap {
    /// Lowercased key character → finger.
    private static let table: [Character: Finger] = {
        var m: [Character: Finger] = [:]
        func assign(_ keys: String, _ finger: Finger) {
            for ch in keys { m[ch] = finger }
        }
        // Left hand
        assign("`1qaz", .leftPinky)
        assign("2wsx", .leftRing)
        assign("3edc", .leftMiddle)
        assign("45rfvtgb", .leftIndex)
        // Right hand
        assign("67yhnujm", .rightIndex)
        assign("8ik,", .rightMiddle)
        assign("9ol.", .rightRing)
        assign("0p;/'[]-=", .rightPinky)
        // Thumb
        assign(" ", .thumb)
        return m
    }()

    /// The finger for a character (case-insensitive). Returns nil for unknown symbols.
    static func finger(for ch: Character) -> Finger? {
        let lower = Character(ch.lowercased())
        return table[lower]
    }

    /// Human-readable finger name for the next-key guide.
    static func fingerLabel(for ch: Character) -> String {
        finger(for: ch)?.label ?? "—"
    }

    /// A friendly display name for a key (handles space and shifted symbols).
    static func displayName(for ch: Character) -> String {
        switch ch {
        case " ": return "space"
        case "\n": return "return"
        default: return String(ch)
        }
    }
}
