import SwiftUI
import UniformTypeIdentifiers

/// A simple text/CSV document used with ShareLink for export.
struct ExportDocument: Transferable {
    let text: String
    let filename: String
    let isCSV: Bool

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { doc in
            Data(doc.text.utf8)
        }
        .suggestedFileName { $0.isCSV ? $0.filename : "\($0.filename)" }

        DataRepresentation(exportedContentType: .plainText) { doc in
            Data(doc.text.utf8)
        }
        .suggestedFileName { $0.filename }
    }
}
