import SwiftUI
import SwiftData
import UIKit

/// Export tasks and history as CSV, with a preview and share sheet.
struct ExportView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \MaintenanceTask.title) private var allTasks: [MaintenanceTask]

    @State private var shareItem: ShareItem?

    private var csv: String {
        ExportBuilder.csv(for: allTasks, hemisphere: settings.hemisphere)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your full task list and completion history as a CSV file you can open in any spreadsheet app.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)

                if allTasks.isEmpty {
                    EmptyStateView(symbol: "square.and.arrow.up",
                                   title: "Nothing to export",
                                   message: "Add tasks and log completions, then export them here.")
                } else {
                    PrimaryButton(title: "Share CSV", systemImage: "square.and.arrow.up") {
                        prepareShare()
                    }

                    Text("Preview")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    Text(previewText)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surfaceAlt))
                }
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }
    }

    private var previewText: String {
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: false).prefix(12)
        return lines.joined(separator: "\n")
    }

    private func prepareShare() {
        let filename = "Upkeep-export.csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try csv.data(using: .utf8)?.write(to: url, options: .atomic)
            shareItem = ShareItem(url: url)
            Haptics.tap(settings.hapticsEnabled)
        } catch {
            // If writing fails, simply do nothing destructive; the button can be retried.
            shareItem = nil
        }
    }
}

/// Identifiable wrapper so the share sheet can be presented via `.sheet(item:)`.
private struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

/// UIKit share sheet bridge.
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
