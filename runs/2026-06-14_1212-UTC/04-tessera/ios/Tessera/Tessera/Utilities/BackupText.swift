import Foundation

/// Builds and parses plain-text backups of accounts.
///
/// Export format is one `otpauth://` URI per line (re-importable everywhere),
/// preceded by a human-readable header. Import is tolerant: it skips blank lines,
/// comment lines (starting with `#`), and any line that isn't a valid otpauth URI.
enum BackupText {

    /// Build the export text from a set of accounts.
    static func export(accounts: [Account]) -> String {
        var lines: [String] = []
        lines.append("# Tessera backup — \(accounts.count) account\(accounts.count == 1 ? "" : "s")")
        lines.append("# Each line below is a standard otpauth:// URI. Keep this file private.")
        lines.append("# Re-import it in Tessera (Backup → Import from text) or any RFC-6238 app.")
        lines.append("")
        for account in accounts.sorted(by: { $0.sortIndex < $1.sortIndex }) {
            lines.append(account.authURI().serialized())
        }
        return lines.joined(separator: "\n")
    }

    /// A readable, non-importable plain list (issuer · label · type) for reference.
    static func plainList(accounts: [Account]) -> String {
        var lines: [String] = ["Tessera accounts:"]
        let sorted = accounts.sorted { $0.displayTitle.lowercased() < $1.displayTitle.lowercased() }
        for account in sorted {
            let subtitle = account.displaySubtitle.isEmpty ? "" : " · \(account.displaySubtitle)"
            lines.append("• \(account.displayTitle)\(subtitle) (\(account.type.shortName), \(account.digits) digits)")
        }
        return lines.joined(separator: "\n")
    }

    /// Parse importable URIs from arbitrary pasted text. Returns the parsed URIs
    /// and the count of lines that were skipped because they weren't valid.
    static func parse(_ text: String) -> (uris: [OTPAuthURI], skipped: Int) {
        var result: [OTPAuthURI] = []
        var skipped = 0
        for rawLine in text.split(whereSeparator: { $0 == "\n" || $0 == "\r" }) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            if let uri = OTPAuthURI.parse(line) {
                result.append(uri)
            } else {
                skipped += 1
            }
        }
        return (result, skipped)
    }
}
