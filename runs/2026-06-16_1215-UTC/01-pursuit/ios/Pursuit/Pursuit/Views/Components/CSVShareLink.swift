import SwiftUI

/// A ShareLink that exports the current pipeline as a CSV file.
/// Falls back to a disabled, explanatory label if the file can't be written.
struct CSVShareLink<Label: View>: View {
    let applications: [Application]
    @ViewBuilder var label: () -> Label

    private var fileURL: URL? {
        CSVExporter.writeTempFile(from: applications.filter { !$0.isArchived })
    }

    var body: some View {
        if let url = fileURL {
            ShareLink(item: url, preview: SharePreview("Pursuit pipeline (CSV)")) {
                label()
            }
            .accessibilityHint("Exports your applications as a CSV file")
        } else {
            label()
                .foregroundStyle(Theme.inkFaint)
                .accessibilityLabel("Export unavailable")
        }
    }
}
