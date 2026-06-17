import SwiftUI
import SwiftData

/// Builds CSV / plain-text exports of completed sessions.
enum ExportBuilder {
    @MainActor
    static func csv(sessions: [WorkoutSession], unit: WeightUnit) -> String {
        var lines = ["date,program,day,exercise,muscle_group,set,weight_\(unit.label),reps,warmup,complete"]
        let sorted = sessions.sorted { $0.date < $1.date }
        for s in sorted {
            let dateStr = ISO8601DateFormatter().string(from: s.date)
            for ex in s.orderedExercises {
                for set in ex.orderedSets {
                    let w = Units.formatNumber(set.weightKg, unit: unit)
                    let row = [
                        dateStr,
                        escape(s.programName),
                        escape(s.dayName),
                        escape(ex.name),
                        ex.group.label,
                        "\(set.setIndex + 1)",
                        w,
                        "\(set.reps)",
                        set.isWarmup ? "yes" : "no",
                        set.isComplete ? "yes" : "no"
                    ].joined(separator: ",")
                    lines.append(row)
                }
            }
        }
        return lines.joined(separator: "\n")
    }

    @MainActor
    static func text(sessions: [WorkoutSession], unit: WeightUnit) -> String {
        var lines = ["ASCEND — Training Log",
                     "Exported \(Date().formatted(date: .abbreviated, time: .omitted))",
                     ""]
        let sorted = sessions.sorted { $0.date > $1.date }
        if sorted.isEmpty { lines.append("No sessions yet.") }
        for s in sorted {
            lines.append("\(s.date.formatted(date: .abbreviated, time: .omitted)) — \(s.dayName) (\(s.programName))")
            for ex in s.orderedExercises {
                let sets = ex.orderedSets
                    .map { "\(Units.formatNumber($0.weightKg, unit: unit))×\($0.reps)" }
                    .joined(separator: ", ")
                lines.append("  • \(ex.name): \(sets)")
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    private static func escape(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return s
    }
}

/// Shows the export with format toggle, copy, and ShareLink.
struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Query(filter: #Predicate<WorkoutSession> { $0.isComplete },
           sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]

    enum Format: String, CaseIterable, Identifiable {
        case csv = "CSV"
        case text = "Text"
        var id: String { rawValue }
    }

    @State private var format: Format = .csv
    @State private var copied = false

    private var output: String {
        switch format {
        case .csv: return ExportBuilder.csv(sessions: sessions, unit: settings.unit)
        case .text: return ExportBuilder.text(sessions: sessions, unit: settings.unit)
        }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                Picker("Format", selection: $format) {
                    ForEach(Format.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(16)
                .onChange(of: format) { _, _ in copied = false }

                ScrollView {
                    Text(output)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(16)
                }
            }
        }
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: output) { Image(systemName: "square.and.arrow.up") }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                UIPasteboard.general.string = output
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
