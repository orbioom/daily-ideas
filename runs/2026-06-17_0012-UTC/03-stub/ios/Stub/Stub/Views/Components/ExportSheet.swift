import SwiftUI
import UIKit

/// Presents exported CSV text with a system share sheet and a copy action.
struct ExportSheet: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    let text: String
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(StubTheme.primaryText(scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(16)
            }
            .background(StubTheme.appBackground(scheme).ignoresSafeArea())
            .navigationTitle("CSV export")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    ShareLink(item: text) {
                        Label("Share CSV", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(StubPrimaryButtonStyle())

                    Button {
                        UIPasteboard.general.string = text
                        copied = true
                    } label: {
                        Label(copied ? "Copied" : "Copy to clipboard",
                              systemImage: copied ? "checkmark" : "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(StubSecondaryButtonStyle())
                }
                .padding(16)
                .background(.ultraThinMaterial)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
