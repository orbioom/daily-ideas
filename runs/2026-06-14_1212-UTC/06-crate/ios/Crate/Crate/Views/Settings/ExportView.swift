import SwiftUI

/// Builds plain-text and CSV exports of the collection.
enum ExportBuilder {
    @MainActor
    static func text(records: [Record], settings: AppSettings) -> String {
        let owned = records.filter { $0.status == .owned }
            .sorted { $0.artist.localizedCaseInsensitiveCompare($1.artist) == .orderedAscending }
        let want = records.filter { $0.status == .wishlist }
            .sorted { $0.artist.localizedCaseInsensitiveCompare($1.artist) == .orderedAscending }

        var lines: [String] = []
        lines.append("CRATE — My Collection")
        lines.append("Exported \(Date().formatted(date: .abbreviated, time: .omitted))")
        lines.append("")

        if owned.isEmpty {
            lines.append("No records in your collection yet.")
        } else {
            lines.append("COLLECTION (\(owned.count))")
            for r in owned {
                let val = settings.hideValues ? "" : "  ·  \(settings.formatMoney(r.estValue))"
                lines.append("• \(r.artist) — \(r.title) (\(r.yearLabel))  ·  \(r.format.display) · \(r.mediaCondition.abbreviation)\(val)")
            }
        }
        if !want.isEmpty {
            lines.append("")
            lines.append("WANTLIST (\(want.count))")
            for r in want {
                lines.append("• \(r.artist) — \(r.title) (\(r.yearLabel))  ·  \(r.format.display)")
            }
        }
        return lines.joined(separator: "\n")
    }

    @MainActor
    static func csv(records: [Record], settings: AppSettings) -> String {
        let header = ["Artist", "Title", "Year", "Format", "Speed", "Genre", "Label", "CatalogNo",
                      "Media", "Sleeve", "PricePaid", "EstValue", "VinylColor", "Status", "Spins"]
        var rows = [header.joined(separator: ",")]
        let sorted = records.sorted { $0.artist.localizedCaseInsensitiveCompare($1.artist) == .orderedAscending }
        for r in sorted {
            let cols: [String] = [
                r.artist, r.title, r.yearLabel == "—" ? "" : r.yearLabel,
                r.format.display, r.speed.display, r.genre.rawValue,
                r.label, r.catalogNo,
                r.mediaCondition.abbreviation, r.sleeveCondition.abbreviation,
                String(format: "%.2f", r.pricePaid), String(format: "%.2f", r.estValue),
                r.vinylColor, r.status.display, String(r.spinCount)
            ]
            rows.append(cols.map(escape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    /// CSV-escape a field (quote when it contains comma, quote, or newline).
    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }
}

/// Shows the export with a text/CSV toggle, copy, and share.
struct ExportView: View {
    let records: [Record]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @State private var asCSV = false
    @State private var copied = false

    private var body_: String {
        asCSV ? ExportBuilder.csv(records: records, settings: settings)
              : ExportBuilder.text(records: records, settings: settings)
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
                    Text(body_)
                        .font(.system(size: 13, design: .monospaced))
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
                    ShareLink(item: body_) { Image(systemName: "square.and.arrow.up") }
                }
            }
            .onChange(of: asCSV) { _, _ in copied = false }
            .safeAreaInset(edge: .bottom) {
                Button {
                    UIPasteboard.general.string = body_
                    copied = true
                    Haptics.success(settings.hapticsEnabled)
                } label: {
                    Label(copied ? "Copied!" : "Copy to clipboard",
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(Theme.rounded(16, .semibold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.accent))
                }
                .padding(.horizontal, 18).padding(.bottom, 12)
            }
        }
    }
}
