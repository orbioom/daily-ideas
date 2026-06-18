import SwiftUI

/// Shows the generated CSV and offers a system share sheet.
struct ExportSheet: View {
    let text: String
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    Text(text)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Theme.ink)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                .background(Theme.surfaceSoft)

                VStack(spacing: 10) {
                    ShareLink(item: text) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share CSV")
                        }
                        .font(Theme.rounded(17, .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(RoundedRectangle(cornerRadius: Theme.radiusButton, style: .continuous).fill(Theme.heroGradient))
                    }
                    Button {
                        UIPasteboard.general.string = text
                        withAnimation { copied = true }
                    } label: {
                        Text(copied ? "Copied" : "Copy to clipboard")
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .padding(20)
                .background(Theme.surface)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Export stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
