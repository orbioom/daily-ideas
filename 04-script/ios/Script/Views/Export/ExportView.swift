import SwiftUI
import SwiftData

struct ExportView: View {
    let project: ScriptProject
    let hasPro: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var pdfData: Data?
    @State private var isGeneratingPDF = false
    @State private var showPDFShare = false
    @State private var showProUpgrade = false

    private var fountainURL: URL? {
        let safe = project.title.isEmpty ? "Untitled" : project.title
        let filename = "\(safe).fountain"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? project.content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private var pageCount: Int {
        FountainParser.estimatePageCount(elements: FountainParser.parse(text: project.content))
    }

    private var wordCount: Int {
        project.content.split(separator: " ").count
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Export") {
                    // PDF Export
                    Button {
                        exportPDF()
                    } label: {
                        HStack {
                            Image(systemName: "doc.richtext.fill")
                                .foregroundColor(.red)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Export as PDF")
                                    .foregroundColor(.primary)
                                Text("Standard screenplay layout")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if isGeneratingPDF {
                                ProgressView()
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }

                    // Fountain Export
                    if let url = fountainURL {
                        ShareLink(
                            item: url,
                            preview: SharePreview(
                                "\(project.title.isEmpty ? "Untitled" : project.title).fountain",
                                image: Image(systemName: "doc.text")
                            )
                        ) {
                            HStack {
                                Image(systemName: "doc.plaintext.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Export as Fountain")
                                        .foregroundColor(.primary)
                                    Text("Open plain-text format (.fountain)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }

                    // Final Draft XML (Pro)
                    Button {
                        if hasPro {
                            exportFDX()
                        } else {
                            showProUpgrade = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.gearshape.fill")
                                .foregroundColor(hasPro ? .scriptAmber : .gray)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Export as Final Draft XML")
                                        .foregroundColor(.primary)
                                    if !hasPro {
                                        ProBadge()
                                    }
                                }
                                Text("Compatible with Final Draft (.fdx)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: hasPro ? "chevron.right" : "lock.fill")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }

                Section("Script Info") {
                    LabeledContent("Title", value: project.title.isEmpty ? "Untitled" : project.title)
                    LabeledContent("Author", value: project.author.isEmpty ? "—" : project.author)
                    LabeledContent("Genre", value: project.genre)
                    LabeledContent("Draft", value: project.draftNumber)
                    LabeledContent("Est. Pages", value: "\(pageCount)")
                    LabeledContent("Words", value: "\(wordCount)")
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPDFShare) {
                if let data = pdfData {
                    PDFShareSheet(data: data, filename: "\(project.title.isEmpty ? "Untitled" : project.title).pdf")
                }
            }
            .sheet(isPresented: $showProUpgrade) {
                ProUpgradeView()
            }
        }
    }

    private func exportPDF() {
        isGeneratingPDF = true
        Task {
            let data = ScriptPDFExporter.export(project: project)
            await MainActor.run {
                pdfData = data
                isGeneratingPDF = false
                showPDFShare = true
            }
        }
    }

    private func exportFDX() {
        let xml = generateFDX()
        let safe = project.title.isEmpty ? "Untitled" : project.title
        let filename = "\(safe).fdx"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? xml.write(to: url, atomically: true, encoding: .utf8)
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let vc = scene.windows.first?.rootViewController {
            vc.present(av, animated: true)
        }
    }

    private func generateFDX() -> String {
        let elements = FountainParser.parse(text: project.content)
        var paragraphs = ""

        for el in elements {
            let typeStr: String
            switch el.type {
            case .sceneHeading: typeStr = "Scene Heading"
            case .action: typeStr = "Action"
            case .character: typeStr = "Character"
            case .dialogue: typeStr = "Dialogue"
            case .parenthetical: typeStr = "Parenthetical"
            case .transition: typeStr = "Transition"
            case .centered: typeStr = "Action"
            default: typeStr = "Action"
            }
            let escaped = el.text
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            paragraphs += "    <Paragraph Type=\"\(typeStr)\"><Text>\(escaped)</Text></Paragraph>\n"
        }

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="no" ?>
        <FinalDraft DocumentType="Script" Template="No" Version="1">
        <Content>
        \(paragraphs)
        </Content>
        </FinalDraft>
        """
    }
}

struct PDFShareSheet: UIViewControllerRepresentable {
    let data: Data
    let filename: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url)
        return UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2.bold())
            .foregroundColor(.black)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(.scriptAmber)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct ProUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [ScriptSettings]

    private var settings: ScriptSettings? { allSettings.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.scriptAmber)
                    .padding(.top, 40)

                Text("Script Pro")
                    .font(.largeTitle.bold())

                Text("One-time purchase. No subscriptions.")
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 14) {
                    ProFeatureRow(icon: "doc.badge.gearshape", text: "Final Draft XML export (.fdx)")
                    ProFeatureRow(icon: "note.text", text: "Story notes per script")
                    ProFeatureRow(icon: "person.2", text: "Character navigator")
                    ProFeatureRow(icon: "list.number", text: "Scene navigator")
                    ProFeatureRow(icon: "moon.stars", text: "Full dark mode themes")
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                Spacer()

                Button {
                    // In production, this triggers StoreKit. For now, unlock directly.
                    settings?.hasPro = true
                    try? modelContext.save()
                    dismiss()
                } label: {
                    Text("Unlock Pro — $6.99")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.scriptAmber)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                Button("Restore Purchases") {
                    // StoreKit restore flow would go here
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 40)
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct ProFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.scriptAmber)
                .frame(width: 24)
            Text(text)
        }
    }
}
