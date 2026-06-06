import SwiftUI
import SwiftData

/// A climb's detail: grade (with cross-system conversion shown), metadata, notes,
/// and the history of attempts logged against it.
struct ClimbDetailView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var climb: Climb

    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false

    private var primaryGrade: String {
        climb.gradeLabel(boulderSystem: settings.boulderSystem, routeSystem: settings.routeSystem)
    }

    /// The "other" system in the same family, shown as a conversion aid.
    private var alternateGrade: String? {
        let alt: GradeSystem
        switch climb.gradeFamily {
        case .boulder: alt = settings.boulderSystem == .vScale ? .font : .vScale
        case .route:   alt = settings.routeSystem == .yds ? .french : .yds
        }
        return GradeScale.display(index: climb.gradeIndex, in: alt).map { "\($0) · \(alt.title)" }
    }

    private var history: [Attempt] {
        climb.attempts.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 14) {
                    gradeCard
                    metaCard
                    if !climb.notes.isEmpty { notesCard }
                    historyCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .navigationTitle(climb.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingEdit = true } label: { Label("Edit climb", systemImage: "pencil") }
                    Button(role: .destructive) { showingDeleteConfirm = true } label: {
                        Label("Delete climb", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Climb options")
            }
        }
        .sheet(isPresented: $showingEdit) {
            ClimbEditView(climb: climb, isNew: false)
        }
        .alert("Delete this climb?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) { deleteClimb() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("The climb is removed. Past attempts keep their grade snapshot in session history.")
        }
    }

    private var gradeCard: some View {
        GlassCard {
            VStack(spacing: 8) {
                Text(primaryGrade)
                    .font(Brand.mono(40, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Brand.text)
                if let alternateGrade {
                    Text(alternateGrade)
                        .font(Brand.mono(15))
                        .foregroundStyle(Brand.text3)
                }
                HStack(spacing: 8) {
                    Label(climb.discipline.title, systemImage: climb.discipline.symbol)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                    if climb.isProject && !climb.isSent {
                        Text("· Project").font(.subheadline).foregroundStyle(Brand.project)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Grade \(primaryGrade)\(alternateGrade.map { ", equivalent to \($0)" } ?? "")")
    }

    private var metaCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                if let location = climb.location {
                    metaRow("Location", location.name, icon: location.kind.symbol)
                }
                if climb.hasColor {
                    HStack {
                        Label("Hold color", systemImage: "circle.fill")
                            .labelStyle(.titleOnly)
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                        Spacer()
                        HoldColorDot(index: climb.colorIndex, size: 16)
                    }
                }
                if let setDate = climb.setDate {
                    metaRow("Set", setDate.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
                }
                metaRow("Sends", "\(climb.sendCount)", icon: "checkmark.circle")
            }
        }
    }

    private func metaRow(_ label: String, _ value: String, icon: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Brand.text)
        }
    }

    private var notesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "Notes")
                Text(climb.notes)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var historyCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "History")
                if history.isEmpty {
                    Text("No attempts logged for this climb yet.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                } else {
                    ForEach(history) { attempt in
                        HStack {
                            Text(attempt.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                                .foregroundStyle(Brand.text2)
                            Spacer()
                            OutcomeBadge(outcome: attempt.outcome, compact: true)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(attempt.createdAt.formatted(date: .abbreviated, time: .omitted)): \(attempt.outcome.title)")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func deleteClimb() {
        context.delete(climb)
        Haptics.warning(enabled: settings.hapticsEnabled)
        dismiss()
    }
}
