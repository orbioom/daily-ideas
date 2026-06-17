import UIKit

/// A tiny wrapper around the system pasteboard so views don't depend on UIKit directly.
enum ClipboardService {
    static func copy(_ text: String) {
        UIPasteboard.general.string = text
    }
}
