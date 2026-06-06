import Foundation

/// Builds CSV and JSON exports of practice data. Pure string production — the views
/// wrap the result in a shareable temp file. No force-unwraps; everything is escaped.
enum Exporter {

    private static var isoFormatter: ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }

    /// Escape a field for RFC-4180 CSV: wrap in quotes and double interior quotes.
    private static func csvField(_ raw: String) -> String {
        let needsQuoting = raw.contains(",") || raw.contains("\"") || raw.contains("\n")
        let escaped = raw.replacingOccurrences(of: "\"", with: "\"\"")
        return needsQuoting ? "\"\(escaped)\"" : escaped
    }

    private static func row(_ fields: [String]) -> String {
        fields.map(csvField).joined(separator: ",")
    }

    // MARK: - Single piece log (CSV)

    /// One row per session that touched the piece, newest-first.
    static func pieceLogCSV(_ piece: Piece) -> String {
        var lines = [row(["date", "minutes", "tempo_bpm", "quality", "focus_notes"])]
        let entries = piece.entries
            .compactMap { entry -> (date: Date, mins: Int, tempo: Int, quality: String, notes: String)? in
                guard let session = entry.session else { return nil }
                return (session.date,
                        entry.minutes,
                        session.tempo,
                        session.quality?.title ?? "",
                        session.focusNotes)
            }
            .sorted { $0.date > $1.date }
        for e in entries {
            lines.append(row([
                isoFormatter.string(from: e.date),
                String(e.mins),
                e.tempo > 0 ? String(e.tempo) : "",
                e.quality,
                e.notes
            ]))
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - All data (JSON)

    /// A stable, human-readable JSON snapshot of every piece, spot, and session.
    static func allDataJSON(pieces: [Piece], sessions: [PracticeSession]) -> String {
        let piecePayload: [[String: Any]] = pieces
            .sorted { $0.createdAt < $1.createdAt }
            .map { piece in
                [
                    "title": piece.title,
                    "composer": piece.composer,
                    "instrument": piece.instrument,
                    "difficulty": piece.difficulty.title,
                    "status": piece.status.title,
                    "key": piece.key,
                    "targetTempo": piece.targetTempo,
                    "notes": piece.notes,
                    "spots": piece.orderedSpots.map { spot in
                        [
                            "name": spot.name,
                            "currentTempo": spot.currentTempo,
                            "targetTempo": spot.targetTempo,
                            "mastery": spot.clampedMastery,
                            "notes": spot.notes
                        ] as [String: Any]
                    }
                ] as [String: Any]
            }

        let sessionPayload: [[String: Any]] = sessions
            .sorted { $0.date > $1.date }
            .map { session in
                [
                    "date": isoFormatter.string(from: session.date),
                    "minutes": session.minutes,
                    "tempo": session.tempo,
                    "quality": session.quality?.title ?? "",
                    "focusNotes": session.focusNotes,
                    "pieces": session.entries.compactMap { entry -> [String: Any]? in
                        guard let p = entry.piece else { return nil }
                        return ["title": p.title, "minutes": entry.minutes]
                    }
                ] as [String: Any]
            }

        let root: [String: Any] = [
            "app": "Repertoire",
            "exportedAt": isoFormatter.string(from: .now),
            "pieces": piecePayload,
            "sessions": sessionPayload
        ]

        guard JSONSerialization.isValidJSONObject(root),
              let data = try? JSONSerialization.data(withJSONObject: root,
                                                     options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }

    // MARK: - All data (CSV)

    /// A flat CSV of every session entry across all pieces, newest-first.
    static func allDataCSV(sessions: [PracticeSession]) -> String {
        var lines = [row(["date", "piece", "minutes", "session_minutes", "tempo_bpm", "quality", "focus_notes"])]
        let sorted = sessions.sorted { $0.date > $1.date }
        for session in sorted {
            if session.entries.isEmpty {
                lines.append(row([
                    isoFormatter.string(from: session.date),
                    "", "0", String(session.minutes),
                    session.tempo > 0 ? String(session.tempo) : "",
                    session.quality?.title ?? "",
                    session.focusNotes
                ]))
                continue
            }
            for entry in session.entries {
                lines.append(row([
                    isoFormatter.string(from: session.date),
                    entry.piece?.title ?? "(removed piece)",
                    String(entry.minutes),
                    String(session.minutes),
                    session.tempo > 0 ? String(session.tempo) : "",
                    session.quality?.title ?? "",
                    session.focusNotes
                ]))
            }
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Temp file wrapping

    /// Write `contents` to a temp file with a safe filename and return its URL, or nil.
    static func temporaryFile(named name: String, contents: String) -> URL? {
        let safe = name
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_.")).inverted)
            .joined(separator: "-")
        let fileName = safe.isEmpty ? "export.txt" : safe
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try contents.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
