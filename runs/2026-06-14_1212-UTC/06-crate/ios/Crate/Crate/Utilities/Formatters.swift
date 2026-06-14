import Foundation

/// Small shared formatting helpers used across screens.
enum Fmt {
    /// Render a total number of seconds as a runtime, e.g. "42:18" or "1:05:30".
    static func runtime(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%d:%02d", m, sec)
    }

    /// Parse a "m:ss" or plain seconds string into seconds; nil when invalid and non-empty.
    static func parseDuration(_ raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return 0 }
        if trimmed.contains(":") {
            let parts = trimmed.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2,
                  let m = Int(parts[0]), m >= 0,
                  let s = Int(parts[1]), s >= 0, s < 60 else { return nil }
            return m * 60 + s
        }
        guard let s = Int(trimmed), s >= 0 else { return nil }
        return s
    }
}
