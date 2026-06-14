import SwiftUI
import UIKit

/// A read-only text export of the library, with a copy-to-clipboard action.
struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    let games: [Game]

    @State private var copied = false

    private var text: String {
        ExportView.buildText(games, settings: settings)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text.isEmpty ? "Your library is empty." : text)
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIPasteboard.general.string = text
                        copied = true
                        Haptics.play(.success, enabled: settings.hapticsEnabled)
                    } label: {
                        Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                    .disabled(games.isEmpty)
                }
            }
        }
    }

    static func buildText(_ games: [Game], settings: AppSettings) -> String {
        guard !games.isEmpty else { return "" }
        let sorted = games.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        var lines: [String] = ["QUEST LIBRARY EXPORT", "\(sorted.count) games", ""]
        for g in sorted {
            let rating = g.personalRating > 0 ? "\(g.personalRating)/10" : "—"
            let length = g.mainStoryHours > 0 ? settings.formatHours(g.mainStoryHours) : "?"
            let logged = settings.formatHours(g.hoursLogged)
            let fav = g.isFavorite ? " ★" : ""
            lines.append("• \(g.title)\(fav)")
            lines.append("  \(g.platform.label) · \(g.genre.label) · \(g.status.label)")
            lines.append("  Rating \(rating) · Length \(length) · Logged \(logged)")
        }
        return lines.joined(separator: "\n")
    }
}
