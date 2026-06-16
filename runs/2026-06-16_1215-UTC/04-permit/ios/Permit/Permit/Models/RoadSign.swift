import Foundation

enum SignKind: String, CaseIterable, Identifiable, Codable {
    case warning = "Warning"
    case regulatory = "Regulatory"
    case guidance = "Guide"
    var id: String { rawValue }
}

/// A road sign described abstractly so it can be drawn with SwiftUI shapes (no image files).
struct RoadSign: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let kind: SignKind
    let meaning: String
    let shapeColorHint: String
    let studyTip: String
}
