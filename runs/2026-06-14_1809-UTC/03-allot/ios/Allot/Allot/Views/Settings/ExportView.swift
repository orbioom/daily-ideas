import SwiftUI
import UIKit

/// Presents the generated CSV with a copy button and a system share sheet.
struct ExportView: View {
    let csv: String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @State private var copied = false

    private var lineCount: Int {
        max(csv.split(separator: "\n", omittingEmptySubsequences: false).count - 1, 0)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    Text(csv)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(Theme.ink)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                .background(Theme.surface)

                VStack(spacing: 10) {
                    ShareLink(item: csv) {
                        Label("Share CSV", systemImage: "square.and.arrow.up")
                            .font(Theme.rounded(17, .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.accent))
                    }
                    Button {
                        UIPasteboard.general.string = csv
                        copied = true
                        Haptics.success(settings.hapticsEnabled)
                    } label: {
                        Text(copied ? "Copied!" : "Copy to clipboard")
                            .font(Theme.rounded(15, .medium))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .padding(16)
                .background(Theme.bg)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("\(lineCount) transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .animation(.easeInOut, value: copied)
        }
    }
}
