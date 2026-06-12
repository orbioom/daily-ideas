import SwiftUI
import SwiftData

struct PreviewView: View {
    @Bindable var resume: Resume
    @AppStorage("paperSize") private var paperRaw = PaperSize.letter.rawValue

    @State private var exporting = false
    @State private var exportedURL: URL?
    @State private var exportError: String?

    private var paper: PaperSize { PaperSize(rawValue: paperRaw) ?? .letter }

    var body: some View {
        VStack(spacing: 0) {
            controls
            Divider()
            ScrollView([.vertical, .horizontal]) {
                ResumeDocumentView(resume: resume, width: paper.pointSize.width)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
                    .padding(24)
                    .accessibilityLabel("Formatted resume preview for \(resume.fullName.isEmpty ? "untitled resume" : resume.fullName)")
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                exportButton
            }
        }
        .sheet(item: Binding(
            get: { exportedURL.map { ShareableURL(url: $0) } },
            set: { if $0 == nil { exportedURL = nil } }
        )) { shareable in
            ShareSheet(url: shareable.url)
                .presentationDetents([.medium, .large])
        }
        .alert("Export Failed", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 10) {
            Picker("Template", selection: Binding(
                get: { resume.template },
                set: { resume.template = $0; Haptics.tap() }
            )) {
                ForEach(TemplateKind.allCases) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                Text("Accent")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(VitaeTheme.accentChoices, id: \.self) { hex in
                    Button {
                        Haptics.tap()
                        resume.accentHex = hex
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 26, height: 26)
                            .overlay {
                                if resume.accentHex == hex {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Accent color \(hex)\(resume.accentHex == hex ? ", selected" : "")")
                }
                Spacer()
                Text(resume.template.blurb)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var exportButton: some View {
        Button {
            exportPDF()
        } label: {
            if exporting {
                ProgressView()
            } else {
                Label("Export PDF", systemImage: "square.and.arrow.up")
            }
        }
        .disabled(exporting)
        .accessibilityLabel(exporting ? "Exporting PDF" : "Export PDF")
    }

    private func exportPDF() {
        Haptics.tap()
        exporting = true
        // ImageRenderer requires the main actor; yield a beat so the spinner shows.
        Task { @MainActor in
            defer { exporting = false }
            do {
                try await Task.sleep(nanoseconds: 60_000_000)
                let url = try PDFExporter.export(resume: resume, paper: paper)
                exportedURL = url
                Haptics.success()
            } catch {
                Haptics.error()
                exportError = error.localizedDescription
            }
        }
    }
}

private struct ShareableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

/// UIKit share sheet — used instead of ShareLink so the PDF exports on tap,
/// not eagerly on every keystroke of the editor.
private struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
