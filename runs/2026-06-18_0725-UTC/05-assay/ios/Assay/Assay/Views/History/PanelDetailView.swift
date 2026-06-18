import SwiftUI
import SwiftData

/// All results from one draw, with status chips, plus edit/delete.
struct PanelDetailView: View {
    let panelId: String

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var results: [LabResult]

    @State private var editing: LabResult?
    @State private var showDeleteConfirm = false
    @State private var showPaywall = false
    @State private var toastData: ToastData?

    private var sex: BiologicalSex { settings.biologicalSex }

    private var panelResults: [LabResult] {
        results.filter { $0.panelId == panelId }
            .sorted { ($0.marker?.category.rawValue ?? "") < ($1.marker?.category.rawValue ?? "") }
    }

    private var panel: Panel? {
        LabAnalytics.panels(from: results).first { $0.id == panelId }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if panelResults.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "Panel removed",
                    message: "This panel no longer has any results."
                )
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        summaryCard
                        resultsCard
                        exportCard
                        deleteButton
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle(panel.map { Fmt.shortDateString($0.drawDate) } ?? "Panel")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { result in
            EditResultSheet(result: result)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .toast($toastData)
        .confirmationDialog("Delete this entire panel?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete panel", role: .destructive) { deletePanel() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All \(panelResults.count) results from this draw will be removed. This cannot be undone.")
        }
    }

    // MARK: - Summary

    @ViewBuilder
    private var summaryCard: some View {
        if let s = StatsEngine.summarize(panelResults: panelResults, sex: sex), let p = panel {
            VStack(spacing: 14) {
                HStack(spacing: 16) {
                    InRangeDonut(optimal: s.optimalCount, inRange: s.inRangeCount, outOfRange: s.outOfRangeCount, lineWidth: 14)
                        .frame(width: 104, height: 104)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(Fmt.date(p.drawDate))
                            .font(Theme.rounded(17, .bold))
                            .foregroundStyle(Theme.ink)
                        if !p.labName.isEmpty {
                            Text(p.labName).font(.footnote).foregroundStyle(Theme.inkSoft)
                        }
                        statLine(color: Theme.good, label: "Optimal", count: s.optimalCount)
                        statLine(color: Theme.okay, label: "In range", count: s.inRangeCount)
                        statLine(color: Theme.bad, label: "Out of range", count: s.outOfRangeCount)
                    }
                    Spacer()
                }
            }
            .assayCard()
        }
    }

    private func statLine(color: Color, label: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(count) \(label.lowercased())")
                .font(.caption)
                .foregroundStyle(Theme.inkSoft)
        }
    }

    // MARK: - Results list

    private var resultsCard: some View {
        VStack(spacing: 0) {
            ForEach(panelResults) { result in
                resultRow(result)
                if result.id != panelResults.last?.id {
                    Divider().background(Theme.hairline)
                }
            }
        }
        .assayCard(padding: 0)
    }

    private func resultRow(_ result: LabResult) -> some View {
        let marker = result.marker
        let assessment: RangeAssessment? = marker.map {
            RangeEngine.assess(marker: $0, rawValue: result.value, rawUnit: result.unitRaw, sex: sex)
        }
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(marker?.name ?? result.markerId)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(Fmt.value(result.value)) \(result.unitRaw)")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            if let a = assessment {
                StatusChip(status: a.status, compact: true)
            }
        }
        .padding(14)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                deleteResult(result)
            } label: { Label("Delete", systemImage: "trash") }
            Button {
                editing = result
            } label: { Label("Edit", systemImage: "pencil") }
                .tint(Theme.accent)
        }
        .onTapGesture { editing = result }
    }

    // MARK: - Export (Pro)

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Doctor report", systemImage: "square.and.arrow.up")
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(Theme.ink)
            Text("Export this panel as a clean CSV and plain-text summary to share with your clinician.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            if pro.isPro {
                HStack(spacing: 12) {
                    ShareLink(item: ReportExporter.csv(panelResults: panelResults, sex: sex),
                              preview: SharePreview("Assay panel CSV")) {
                        exportButton(icon: "tablecells", label: "CSV")
                    }
                    ShareLink(item: ReportExporter.textSummary(panelResults: panelResults, sex: sex),
                              preview: SharePreview("Assay panel summary")) {
                        exportButton(icon: "doc.text", label: "Text")
                    }
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "lock.fill")
                        Text("Unlock export with Pro")
                            .font(Theme.rounded(15, .semibold))
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
        }
        .assayCard()
    }

    private func exportButton(icon: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(label).font(Theme.rounded(14, .semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.accentSoft)
        .foregroundStyle(Theme.accent)
        .clipShape(Capsule())
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Label("Delete panel", systemImage: "trash")
                .font(Theme.rounded(15, .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Theme.bad.opacity(0.12))
                .foregroundStyle(Theme.bad)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Mutations

    private func deleteResult(_ result: LabResult) {
        context.delete(result)
        try? context.save()
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
        toastData = ToastData(icon: "trash", message: "Result deleted", tint: Theme.bad)
        if panelResults.isEmpty { dismiss() }
    }

    private func deletePanel() {
        for r in panelResults { context.delete(r) }
        try? context.save()
        Haptics.warning(enabled: settings.hapticsEnabled)
        dismiss()
    }
}
