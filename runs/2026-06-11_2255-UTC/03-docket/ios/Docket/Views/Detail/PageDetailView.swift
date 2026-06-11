import SwiftUI

struct PageDetailView: View {
    let page: ScanPage
    @State private var showingText = false
    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $showingText) {
                Text("Image").tag(false)
                Text("Text").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(16)

            if showingText {
                textPane
            } else {
                imagePane
            }
        }
        .background(Theme.bgPrimary)
        .navigationTitle("Page \(page.order + 1)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var imagePane: some View {
        Group {
            if let image = ImageStore.load(page.fileName) {
                ScrollView([.horizontal, .vertical]) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: UIScreen.main.bounds.width - 32)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(16)
                        .accessibilityLabel("Scanned page image")
                }
            } else {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Image missing",
                    message: "This page's image file couldn't be loaded from storage."
                )
            }
        }
    }

    private var textPane: some View {
        Group {
            if page.ocrText.isEmpty {
                EmptyStateView(
                    icon: "text.viewfinder",
                    title: "No text yet",
                    message: "Either recognition is still running, or no readable text was found on this page."
                )
            } else {
                ScrollView {
                    Text(page.ocrText)
                        .font(.body.monospaced())
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(16)
                }
                .safeAreaInset(edge: .bottom) {
                    Button {
                        UIPasteboard.general.string = page.ocrText
                        copied = true
                        Haptics.success()
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(2))
                            copied = false
                        }
                    } label: {
                        Label(copied ? "Copied" : "Copy all text",
                              systemImage: copied ? "checkmark" : "doc.on.doc")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.accent.opacity(copied ? 0.5 : 1),
                                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundStyle(.white)
                    }
                    .padding(16)
                    .accessibilityHint("Copies the recognized text to the clipboard")
                }
            }
        }
    }
}
