import SwiftUI
import SwiftData

/// Exports the cook log as shareable plain text (Pro feature).
struct ExportView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Cook.createdAt, order: .reverse) private var cooks: [Cook]

    private var exportText: String {
        guard !cooks.isEmpty else { return "No cooks logged yet." }
        var lines: [String] = ["Sear — Cook Log", ""]
        for cook in cooks {
            lines.append("• \(cook.name) [\(cook.status.label)]")
            lines.append("  \(cook.protein.label) · \(cook.cut) · \(settings.weight(cook.weightKg)) · \(cook.method.label)")
            lines.append("  Target \(settings.temp(cook.targetInternalTempC)) · Pit \(settings.temp(cook.ambientTempC))")
            if let wood = cook.woodType { lines.append("  Wood: \(wood)") }
            if let rub = cook.rubName { lines.append("  Rub: \(rub)") }
            if let rating = cook.clampedRating { lines.append("  Rating: \(rating)/5") }
            if !cook.notes.isEmpty { lines.append("  Notes: \(cook.notes)") }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        Text(exportText)
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .searCard()

                        ShareLink(item: exportText) {
                            Label("Share export", systemImage: "square.and.arrow.up")
                                .font(Theme.rounded(16, .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accent))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
