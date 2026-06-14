import SwiftUI

/// Builds the plain-text export of progress + routines.
enum ExportBuilder {
    @MainActor
    static func build(routines: [Routine], runs: [RoutineRun], settings: AppSettings) -> String {
        let stats = RoutineEngine.compute(runs: runs,
                                          routines: routines,
                                          settings: settings.weekStart.firstWeekday,
                                          threshold: settings.completionThreshold)
        var lines: [String] = []
        lines.append("DAYBREAK — My Routines & Progress")
        lines.append("Exported \(Date().formatted(date: .abbreviated, time: .omitted))")
        lines.append("")
        lines.append("Current streak: \(stats.currentStreak) days")
        lines.append("Longest streak: \(stats.longestStreak) days")
        lines.append("Total runs: \(stats.totalRuns)  ·  Completed: \(stats.completedRuns)")
        lines.append("Total minutes: \(stats.totalMinutes)")
        lines.append("")

        lines.append("ROUTINES")
        if routines.isEmpty {
            lines.append("No routines yet.")
        } else {
            for routine in routines.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                lines.append("• \(routine.name) (\(routine.timeOfDay.label)) — \(routine.orderedSteps.count) steps, \(TimeFormat.minutesLabel(routine.estimatedMinutes))")
                for step in routine.orderedSteps {
                    let detail = step.kind == .timed ? TimeFormat.clock(step.durationSec) : "check"
                    lines.append("    – \(step.title) [\(detail)]")
                }
            }
        }

        if !stats.perRoutine.isEmpty {
            lines.append("")
            lines.append("COMPLETION")
            for item in stats.perRoutine {
                lines.append("• \(item.name): \(Int((item.rate * 100).rounded()))% (\(item.completed)/\(item.runs))")
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
                    ShareLink(item: text) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share export")
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
                        .foregroundStyle(Theme.onAccent)
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
