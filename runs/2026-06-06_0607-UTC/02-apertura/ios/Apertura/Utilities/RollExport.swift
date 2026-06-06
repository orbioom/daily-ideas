import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// A generated, shareable document for exporting a roll's log. Conforms to
/// `Transferable` so it drops straight into a SwiftUI `ShareLink` — no UIKit bridge.
struct RollDocument: Transferable {
    enum Kind {
        case csv, json
    }

    var fileName: String
    var text: String
    var kind: Kind

    static var transferRepresentation: some TransferRepresentation {
        // CSV and JSON both serialize the same text payload; the type is set per-export.
        DataRepresentation(exportedContentType: .commaSeparatedText) { doc in
            Data(doc.text.utf8)
        }
        .suggestedFileName { $0.fileName }

        DataRepresentation(exportedContentType: .json) { doc in
            Data(doc.text.utf8)
        }
        .suggestedFileName { $0.fileName }

        DataRepresentation(exportedContentType: .plainText) { doc in
            Data(doc.text.utf8)
        }
        .suggestedFileName { $0.fileName }
    }
}

/// Pure serialization of a roll + its frames to CSV or JSON. No I/O, no SwiftUI.
enum RollExport {

    /// Sanitize a string into a safe file-name stem.
    private static func slug(_ s: String) -> String {
        let allowed = CharacterSet.alphanumerics
        let cleaned = s.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let joined = String(cleaned)
        let trimmed = joined.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return trimmed.isEmpty ? "roll" : trimmed
    }

    private static func csvField(_ s: String) -> String {
        // Quote any field with comma, quote, or newline; escape inner quotes.
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return s
    }

    static func csv(for roll: Roll) -> RollDocument {
        var lines: [String] = []
        lines.append("frame,aperture,shutter,focal_mm,iso,ev,ev100,subject,location,notes")
        for f in roll.orderedFrames {
            let ev = f.ev.map { Exposure.evString($0) } ?? ""
            let ev100 = f.ev100.map { Exposure.evString($0) } ?? ""
            let row = [
                String(f.number),
                Exposure.apertureString(f.aperture),
                Exposure.shutterString(f.shutterSeconds),
                String(format: "%.0f", f.focalLengthMM),
                String(format: "%.0f", roll.iso),
                ev,
                ev100,
                csvField(f.subject),
                csvField(f.location),
                csvField(f.notes)
            ].joined(separator: ",")
            lines.append(row)
        }
        let text = lines.joined(separator: "\n")
        return RollDocument(fileName: "\(slug(roll.filmStock)).csv", text: text, kind: .csv)
    }

    static func json(for roll: Roll) -> RollDocument {
        let frames: [[String: Any]] = roll.orderedFrames.map { f in
            [
                "frame": f.number,
                "aperture": f.aperture,
                "aperture_label": Exposure.apertureString(f.aperture),
                "shutter_seconds": f.shutterSeconds,
                "shutter_label": Exposure.shutterString(f.shutterSeconds),
                "focal_mm": f.focalLengthMM,
                "ev": f.ev as Any? ?? NSNull(),
                "ev100": f.ev100 as Any? ?? NSNull(),
                "subject": f.subject,
                "location": f.location,
                "notes": f.notes
            ]
        }
        let object: [String: Any] = [
            "film_stock": roll.filmStock,
            "iso": roll.iso,
            "format": roll.format.rawValue,
            "camera": roll.camera,
            "notes": roll.notes,
            "frame_count": roll.frames.count,
            "frames": frames
        ]

        let text: String
        if let data = try? JSONSerialization.data(withJSONObject: object,
                                                  options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: data, encoding: .utf8) {
            text = str
        } else {
            // Honest fallback rather than a crash if serialization ever fails.
            text = "{\"film_stock\":\"\(roll.filmStock)\",\"frames\":\(roll.frames.count)}"
        }
        return RollDocument(fileName: "\(slug(roll.filmStock)).json", text: text, kind: .json)
    }
}
