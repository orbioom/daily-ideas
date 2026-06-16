import SwiftUI

/// Builds a CSV export of all decks & cards.
enum ExportBuilder {
    static func buildCSV(decks: [Deck]) -> String {
        var rows: [String] = []
        rows.append("Deck,Category,Front,Back,Hint,Example,Maturity,IntervalDays,Ease,Reps,Lapses,Suspended,DueDate")
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        for deck in decks.sorted(by: { $0.name < $1.name }) {
            for card in deck.cards.sorted(by: { $0.createdDate < $1.createdDate }) {
                let cols = [
                    deck.name,
                    deck.category,
                    card.front,
                    card.back,
                    card.hint,
                    card.example,
                    card.maturity.rawValue,
                    "\(card.intervalDays)",
                    String(format: "%.2f", card.ease),
                    "\(card.repetitions)",
                    "\(card.lapses)",
                    card.isSuspended ? "yes" : "no",
                    fmt.string(from: card.dueDate)
                ]
                rows.append(cols.map(escape).joined(separator: ","))
            }
        }
        return rows.joined(separator: "\n")
    }

    /// CSV-escape a field: wrap in quotes if it contains a comma, quote, or newline.
    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let doubled = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(doubled)\""
        }
        return field
    }
}

/// Shows the CSV text with copy + share.
struct ExportView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(18)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Export CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: text) { Image(systemName: "square.and.arrow.up") }
                        .accessibilityLabel("Share CSV")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    UIPasteboard.general.string = text
                    copied = true
                    Haptics.success(enabled: settings.hapticsEnabled)
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
