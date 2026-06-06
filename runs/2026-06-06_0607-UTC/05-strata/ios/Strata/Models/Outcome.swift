import Foundation

/// The result of a single attempt on a climb.
/// `flash`, `onsight`, `redpoint`, and `repeat` are all "sends" (topped out).
/// `fall` is an unfinished attempt (worked the climb but did not top).
enum Outcome: String, CaseIterable, Identifiable, Codable {
    case flash
    case onsight
    case redpoint
    case `repeat`
    case fall

    var id: String { rawValue }

    var title: String {
        switch self {
        case .flash:    return "Flash"
        case .onsight:  return "Onsight"
        case .redpoint: return "Send"
        case .repeat:   return "Repeat"
        case .fall:     return "Fall / Attempt"
        }
    }

    /// Short label used in dense lists.
    var shortTitle: String {
        switch self {
        case .flash:    return "Flash"
        case .onsight:  return "Onsight"
        case .redpoint: return "Send"
        case .repeat:   return "Repeat"
        case .fall:     return "Attempt"
        }
    }

    /// Whether the climb was topped out (counts toward the send pyramid).
    var isSend: Bool { self != .fall }

    /// A first-go clean ascent (flash or onsight) — counts toward flash/onsight rate.
    var isFirstGo: Bool { self == .flash || self == .onsight }

    var symbol: String {
        switch self {
        case .flash:    return "bolt.fill"
        case .onsight:  return "eye.fill"
        case .redpoint: return "checkmark.circle.fill"
        case .repeat:   return "arrow.clockwise"
        case .fall:     return "arrow.down.circle"
        }
    }
}
