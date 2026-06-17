import SwiftUI
import SwiftData
import UIKit

/// Export logged swims as plain text that can be copied or shared.
struct ExportView: View {
    @Query(sort: \SwimSession.date, order: .reverse) private var sessions: [SwimSession]
    @AppStorage(PrefKey.unitsRaw) private var unitsRaw = DistanceUnit.meters.rawValue
    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled = true
    @State private var copied = false

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitsRaw) ?? .meters }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            content
        }
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        if sessions.isEmpty {
            EmptyStateView(symbol: "square.and.arrow.up",
                           title: "Nothing to export",
                           message: "Log a swim first, then export your history here.")
        } else {
            VStack(spacing: 16) {
                ScrollView {
                    Text(exportText)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
                }
                VStack(spacing: 10) {
                    ShareLink(item: exportText) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(Theme.rounded(16, .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.accentSoft))
                            .foregroundStyle(Theme.accent)
                    }
                    Button {
                        UIPasteboard.general.string = exportText
                        copied = true
                        Haptics.success(hapticsEnabled)
                    } label: {
                        Text(copied ? "Copied" : "Copy to clipboard")
                            .font(Theme.rounded(15, .medium))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }
            .padding(20)
        }
    }

    private var exportText: String {
        let fmt = UnitFormatter(unit: unit)
        var lines: [String] = ["Wake — swim log export", ""]
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm"
        for session in sessions {
            lines.append("• \(df.string(from: session.date)) — \(session.workoutName ?? "Free swim")")
            lines.append("  \(fmt.distance(session.totalDistanceMeters)) in \(UnitFormatter.clock(Double(session.durationSeconds)))")
            if let pace = SwimMath.pacePer100(seconds: Double(session.durationSeconds),
                                              distanceMeters: session.totalDistanceMeters) {
                lines.append("  avg \(fmt.pacePer100(pace))")
            }
            if let rpe = session.rpe {
                lines.append("  RPE \(rpe)")
            }
            for set in session.orderedSets {
                lines.append("    \(set.repeats)×\(Int(unit.value(fromMeters: set.distancePerRepMeters)))\(unit.shortUnit) \(set.stroke.label) — \(UnitFormatter.clock(set.actualTimeSeconds))")
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}
