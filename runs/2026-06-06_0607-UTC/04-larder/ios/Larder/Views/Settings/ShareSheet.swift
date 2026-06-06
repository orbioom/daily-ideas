import SwiftUI
import UIKit

/// Wraps `UIActivityViewController` to share exported inventory text as a temporary
/// file (so it can be saved to Files, AirDropped, etc.). Falls back to sharing the raw
/// string if the temp file can't be written — never crashes.
struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    let fileName: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let items: [Any] = fileURL().map { [$0] } ?? [text]
        return UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}

    /// Writes the text to a temp file and returns its URL, or nil on failure.
    private func fileURL() -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try text.data(using: .utf8)?.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
