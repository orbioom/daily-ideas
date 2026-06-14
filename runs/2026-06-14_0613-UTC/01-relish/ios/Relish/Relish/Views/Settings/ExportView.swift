import SwiftUI

/// Builds the plain-text export of the ranked list.
enum ExportBuilder {
    @MainActor
    static func build(restaurants: [Restaurant], settings: AppSettings) -> String {
        let book = ScoreBook(allRestaurants: restaurants)
        let ranked = restaurants
            .filter { !$0.isWishlist && $0.sentiment != nil }
            .sorted { $0.rankIndex < $1.rankIndex }
        let wishlist = restaurants.filter { $0.isWishlist }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        var lines: [String] = []
        lines.append("RELISH — My Ranked Restaurants")
        lines.append("Exported \(Date().formatted(date: .abbreviated, time: .omitted))")
        lines.append("")

        if ranked.isEmpty {
            lines.append("No ranked places yet.")
        } else {
            for (i, r) in ranked.enumerated() {
                let score = settings.formatScore(book.score(r))
                let city = r.city.isEmpty ? "" : " · \(r.city)"
                lines.append("\(i + 1). \(r.name) — \(score)  (\(r.cuisine.rawValue) · \(r.priceLabel)\(city))")
            }
        }

        if !wishlist.isEmpty {
            lines.append("")
            lines.append("WANT TO TRY")
            for r in wishlist {
                let city = r.city.isEmpty ? "" : " · \(r.city)"
                lines.append("• \(r.name)  (\(r.cuisine.rawValue)\(city))")
            }
        }

        return lines.joined(separator: "\n")
    }
}

/// Shows the export text with copy + share.
struct ExportView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(18)
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
        }
    }
}
