import SwiftUI
import UIKit

/// Builds the plain-text shopping list export.
enum ShoppingExportBuilder {
    /// `needs` is a list of (ingredient name, recipe count).
    static func build(needs: [(String, Int)]) -> String {
        var lines: [String] = []
        lines.append("SKILLET — Shopping List")
        lines.append("Exported \(Date().formatted(date: .abbreviated, time: .omitted))")
        lines.append("")
        if needs.isEmpty {
            lines.append("Nothing to buy — you're fully stocked.")
        } else {
            for (name, count) in needs {
                let suffix = count > 1 ? "  (\(count) recipes)" : ""
                lines.append("• \(name)\(suffix)")
            }
        }
        return lines.joined(separator: "\n")
    }
}

/// Shows the export text with copy + share.
struct ShoppingExportView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(18)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: text) { Image(systemName: "square.and.arrow.up") }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    UIPasteboard.general.string = text
                    copied = true
                    Haptics.success(settings.hapticsEnabled)
                } label: {
                    Label(copied ? "Copied!" : "Copy to clipboard",
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.accent))
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
            }
        }
    }
}
