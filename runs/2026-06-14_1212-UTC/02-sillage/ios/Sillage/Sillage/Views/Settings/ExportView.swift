import SwiftUI

/// The export format: a readable text list, or CSV.
enum ExportFormat: String, CaseIterable, Identifiable {
    case text = "Text"
    case csv = "CSV"
    var id: String { rawValue }
}

/// Builds the export of the collection + wear log.
enum ExportBuilder {
    @MainActor
    static func build(fragrances: [Fragrance], settings: AppSettings, format: ExportFormat) -> String {
        let sorted = fragrances.sorted {
            if $0.house != $1.house { return $0.house.localizedCaseInsensitiveCompare($1.house) == .orderedAscending }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        switch format {
        case .text: return buildText(sorted, settings: settings)
        case .csv: return buildCSV(sorted, settings: settings)
        }
    }

    @MainActor
    private static func buildText(_ list: [Fragrance], settings: AppSettings) -> String {
        var lines: [String] = []
        lines.append("SILLAGE — My Fragrance Collection")
        lines.append("Exported \(Date().formatted(date: .abbreviated, time: .omitted))")
        lines.append("")
        if list.isEmpty {
            lines.append("No fragrances yet.")
            return lines.joined(separator: "\n")
        }
        for f in list {
            let price = settings.hidePrices ? "" : (f.pricePaid > 0 ? " · \(settings.formatMoneyAlways(f.pricePaid))" : "")
            lines.append("\(f.name) — \(f.house)")
            lines.append("  \(f.concentration.rawValue) · \(f.status.rawValue) · worn \(f.timesWorn)×\(price)")
            let top = f.orderedNotes(in: .top).map(\.displayName).joined(separator: ", ")
            let heart = f.orderedNotes(in: .heart).map(\.displayName).joined(separator: ", ")
            let base = f.orderedNotes(in: .base).map(\.displayName).joined(separator: ", ")
            if !top.isEmpty { lines.append("  Top: \(top)") }
            if !heart.isEmpty { lines.append("  Heart: \(heart)") }
            if !base.isEmpty { lines.append("  Base: \(base)") }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    @MainActor
    private static func buildCSV(_ list: [Fragrance], settings: AppSettings) -> String {
        var rows: [String] = []
        rows.append("Name,House,Concentration,Status,Size mL,Price,Bottles,Rating,Times Worn,Cost Per Wear,Top,Heart,Base")
        for f in list {
            let price = settings.hidePrices ? "" : String(format: "%.2f", f.pricePaid)
            let cpw = (settings.hidePrices || f.pricePaid <= 0) ? "" : String(format: "%.2f", f.costPerWear)
            let cells: [String] = [
                f.name, f.house, f.concentration.rawValue, f.status.rawValue,
                String(format: "%.0f", f.sizeML), price, String(f.bottlesOwned),
                String(f.rating), String(f.timesWorn), cpw,
                f.orderedNotes(in: .top).map(\.displayName).joined(separator: "; "),
                f.orderedNotes(in: .heart).map(\.displayName).joined(separator: "; "),
                f.orderedNotes(in: .base).map(\.displayName).joined(separator: "; ")
            ]
            rows.append(cells.map(escape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    private static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}

/// Shows the export text with a format switcher, copy, and share.
struct ExportView: View {
    let fragrances: [Fragrance]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @State private var format: ExportFormat = .text
    @State private var copied = false

    private var text: String {
        ExportBuilder.build(fragrances: fragrances, settings: settings, format: format)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Format", selection: $format) {
                    ForEach(ExportFormat.allCases) { f in Text(f.rawValue).tag(f) }
                }
                .pickerStyle(.segmented)
                .padding(16)

                ScrollView {
                    Text(text)
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
            .onChange(of: format) { _, _ in copied = false }
        }
    }
}
