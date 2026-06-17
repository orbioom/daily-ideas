import SwiftUI
import SwiftData

/// Exports the learner's progress as plain-text CSV, shareable via the system sheet.
struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var stats: [ItemStat]
    @Query private var sessions: [DrillSession]

    private var csv: String {
        var lines: [String] = []
        lines.append("VERBO PROGRESS EXPORT")
        lines.append("Generated \(Date.now.formatted(date: .abbreviated, time: .shortened))")
        lines.append("")
        lines.append("ITEM STATS")
        lines.append("language,verb,tense,correct,attempts,mastery")
        for s in stats.sorted(by: { $0.id < $1.id }) {
            let m = String(format: "%.2f", s.mastery)
            lines.append("\(s.language),\(s.verbInfinitive),\(s.tense),\(s.correct),\(s.attempts),\(m)")
        }
        lines.append("")
        lines.append("SESSIONS")
        lines.append("date,language,mode,correct,total,seconds")
        let df = ISO8601DateFormatter()
        for s in sessions.sorted(by: { $0.date < $1.date }) {
            lines.append("\(df.string(from: s.date)),\(s.language),\(s.mode),\(s.correct),\(s.total),\(s.durationSeconds)")
        }
        return lines.joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if stats.isEmpty && sessions.isEmpty {
                    EmptyStateView(symbol: "square.and.arrow.up",
                                   title: "Nothing to export",
                                   message: "Complete a session first, then come back to export your progress.")
                } else {
                    VStack(spacing: 16) {
                        ScrollView {
                            Text(csv)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(Theme.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                                .padding(16)
                        }
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))

                        ShareLink(item: csv) {
                            Label("Share export", systemImage: "square.and.arrow.up")
                                .font(Theme.rounded(16, .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.accent))
                                .foregroundStyle(.white)
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
