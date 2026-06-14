import SwiftUI

/// Builds plain-text and CSV exports of the library.
enum ExportBuilder {

    static func buildText(titles: [Title]) -> String {
        let sorted = titles.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        var lines: [String] = []
        lines.append("SENPAI — My Library")
        lines.append("Exported \(Date().formatted(date: .abbreviated, time: .omitted))")
        lines.append("\(titles.count) titles")
        lines.append("")

        if sorted.isEmpty {
            lines.append("No titles yet.")
            return lines.joined(separator: "\n")
        }

        for kind in AnimeMediaKind.allCases {
            let group = sorted.filter { $0.kind == kind }
            guard !group.isEmpty else { continue }
            lines.append("— \(kind.rawValue.uppercased()) —")
            for t in group {
                let score = t.score > 0 ? " · \(t.score)/10" : ""
                let season = t.seasonLabel.map { " · \($0)" } ?? ""
                lines.append("• \(t.name) — \(t.statusLabel) · \(t.progressLabel)\(score)\(season)")
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    static func buildCSV(titles: [Title]) -> String {
        var rows: [String] = []
        rows.append("Name,Kind,Status,Progress,Total,Score,Season,Year,Studio/Author,Rewatches,Genres")
        let sorted = titles.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        for t in sorted {
            let total = t.totalUnits.map(String.init) ?? ""
            let season = t.season?.rawValue ?? ""
            let year = t.seasonYear.map(String.init) ?? ""
            let genres = t.genres.map(\.name).sorted().joined(separator: "; ")
            let fields = [
                t.name, t.kind.rawValue, t.statusLabel, "\(t.progress)", total,
                "\(t.score)", season, year, t.studioOrAuthor, "\(t.rewatchCount)", genres
            ]
            rows.append(fields.map(escape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }
}

/// Shows the export with a format toggle, copy, and share.
struct ExportView: View {
    let titles: [Title]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @State private var asCSV = false
    @State private var copied = false

    private var text: String {
        asCSV ? ExportBuilder.buildCSV(titles: titles) : ExportBuilder.buildText(titles: titles)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Format", selection: $asCSV) {
                    Text("Text").tag(false)
                    Text("CSV").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(16)

                ScrollView {
                    Text(text)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(18)
                }
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
            .onChange(of: asCSV) { copied = false }
        }
    }
}
