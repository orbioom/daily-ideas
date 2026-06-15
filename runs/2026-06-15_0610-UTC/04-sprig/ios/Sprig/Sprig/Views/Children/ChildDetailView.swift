import SwiftUI
import SwiftData

/// A child's hub: header, percentile snapshot, and quick links into Growth, Milestones, Vaccines.
struct ChildDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("selectedChildID") private var selectedChildID = ""

    @Bindable var child: Child

    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    private var summary: ChildSummary { ChildSummary.build(for: child) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                snapshotCard
                quickLinks
                proCard
                disclaimer
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(child.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Edit details", systemImage: "pencil") }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Delete child", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Child options")
            }
        }
        .sheet(isPresented: $showEdit) {
            AddChildView(existing: child)
        }
        .confirmationDialog("Delete \(child.displayName)?",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) { deleteChild() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes all measurements, milestones, and vaccine records for this child.")
        }
        .onAppear { selectedChildID = child.id.uuidString }
    }

    private var header: some View {
        CardView {
            HStack(spacing: 14) {
                ChildAvatar(child: child, size: 60)
                VStack(alignment: .leading, spacing: 3) {
                    Text(child.displayName)
                        .font(Theme.rounded(24, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("\(child.sex.title) · \(summary.ageDescription)")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                    Text("Born \(child.birthDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkFaint)
                }
                Spacer()
            }
        }
    }

    private var snapshotCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Latest percentiles", systemImage: "chart.xyaxis.line")
                if summary.measurementCount > 0 {
                    HStack(spacing: 8) {
                        PercentilePill(measure: .weight, result: summary.weightPercentile)
                        PercentilePill(measure: .height, result: summary.heightPercentile)
                        PercentilePill(measure: .head, result: summary.headPercentile)
                    }
                    Text("Based on the most recent of \(summary.measurementCount) measurement\(summary.measurementCount == 1 ? "" : "s") · \(settings.growthStandard.short) reference")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                } else {
                    Text("No measurements yet. Add one on the Growth tab to see percentiles here.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
    }

    private var quickLinks: some View {
        VStack(spacing: 12) {
            NavigationLink {
                GrowthDetailView(child: child)
            } label: {
                linkRow(symbol: "chart.xyaxis.line", title: "Growth charts",
                        subtitle: "\(summary.measurementCount) measurement\(summary.measurementCount == 1 ? "" : "s")",
                        tint: Theme.accent)
            }
            .buttonStyle(.plain)

            NavigationLink {
                MilestonesDetailView(child: child)
            } label: {
                linkRow(symbol: "checklist", title: "Milestones",
                        subtitle: milestoneSubtitle,
                        tint: Theme.good)
            }
            .buttonStyle(.plain)

            NavigationLink {
                VaccinesDetailView(child: child)
            } label: {
                linkRow(symbol: "cross.case.fill", title: "Vaccines",
                        subtitle: vaccineSubtitle,
                        tint: summary.overdueVaccineCount > 0 ? Theme.bad : Theme.accent)
            }
            .buttonStyle(.plain)
        }
    }

    private var milestoneSubtitle: String {
        let achieved = child.milestoneRecords.filter { $0.isAchieved }.count
        return "\(achieved) achieved"
    }

    private var vaccineSubtitle: String {
        if summary.overdueVaccineCount > 0 {
            return "\(summary.overdueVaccineCount) overdue"
        }
        let given = child.vaccineRecords.filter { $0.isGiven }.count
        return "\(given) given"
    }

    private func linkRow(symbol: String, title: String, subtitle: String, tint: Color) -> some View {
        CardView {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 30)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.rounded(17, .semibold)).foregroundStyle(Theme.ink)
                    Text(subtitle).font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
                    .accessibilityHidden(true)
            }
        }
    }

    private var proCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Share & export", systemImage: "square.and.arrow.up")
                NavigationLink {
                    ExportView(child: child)
                } label: {
                    HStack {
                        Label("Pediatrician report & CSV", systemImage: "doc.text")
                            .font(Theme.rounded(15, .medium))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        if !isPro {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.inkFaint)
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var disclaimer: some View {
        Text("Informational only — not medical advice. Always follow your pediatrician's guidance.")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
    }

    private func deleteChild() {
        let wasSelected = selectedChildID == child.id.uuidString
        context.delete(child)
        try? context.save()
        if wasSelected { selectedChildID = "" }
        Haptics.warn(settings.hapticsEnabled)
        dismiss()
    }
}
