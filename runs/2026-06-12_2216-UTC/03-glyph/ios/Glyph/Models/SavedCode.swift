import Foundation
import SwiftData

/// A QR code the user designed and kept in the library.
@Model
final class SavedCode {
    var title: String
    var kindRaw: String
    /// JSON-encoded PayloadDraft so codes stay editable later.
    var draftData: Data
    var foregroundHex: String
    var backgroundHex: String
    var correctionRaw: String
    var createdAt: Date
    var isFavorite: Bool

    init(
        title: String,
        draft: PayloadDraft,
        foregroundHex: String,
        backgroundHex: String,
        correctionRaw: String,
        createdAt: Date = .now,
        isFavorite: Bool = false
    ) {
        self.title = title
        self.kindRaw = draft.kind.rawValue
        self.draftData = (try? JSONEncoder().encode(draft)) ?? Data()
        self.foregroundHex = foregroundHex
        self.backgroundHex = backgroundHex
        self.correctionRaw = correctionRaw
        self.createdAt = createdAt
        self.isFavorite = isFavorite
    }

    var kind: PayloadKind { PayloadKind(rawValue: kindRaw) ?? .text }

    var draft: PayloadDraft? {
        try? JSONDecoder().decode(PayloadDraft.self, from: draftData)
    }
}

/// One scan result (camera or photo import).
@Model
final class ScanRecord {
    var payload: String
    var detectedKindRaw: String
    var date: Date
    var fromCamera: Bool

    init(payload: String, detectedKind: PayloadKind, date: Date = .now, fromCamera: Bool) {
        self.payload = payload
        self.detectedKindRaw = detectedKind.rawValue
        self.date = date
        self.fromCamera = fromCamera
    }

    var detectedKind: PayloadKind { PayloadKind(rawValue: detectedKindRaw) ?? .text }
}

/// Classifies a scanned string into the payload taxonomy for display/actions.
enum PayloadClassifier {
    static func classify(_ string: String) -> PayloadKind {
        let lower = string.lowercased()
        if lower.hasPrefix("wifi:") { return .wifi }
        if lower.hasPrefix("begin:vcard") { return .contact }
        if lower.hasPrefix("mailto:") { return .email }
        if lower.hasPrefix("smsto:") || lower.hasPrefix("sms:") { return .sms }
        if lower.hasPrefix("tel:") { return .phone }
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") { return .url }
        return .text
    }
}
