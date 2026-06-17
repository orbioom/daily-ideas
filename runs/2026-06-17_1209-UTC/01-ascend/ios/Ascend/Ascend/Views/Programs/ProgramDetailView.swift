import SwiftUI
import SwiftData

/// Detail for a saved program: days, exercises, set active, delete.
struct ProgramDetailView: View {
    @Bindable var program: Program
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Query private var allPrograms: [Program]

    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard
                    ForEach(program.orderedDays) { day in
                        dayCard(day)
                    }
                    if !program.isActive {
                        PrimaryButton(title: "Set as active program", systemImage: "checkmark.circle") {
                            setActive()
                        }
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete program", systemImage: "trash")
                            .font(Theme.rounded(15, .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .foregroundStyle(Theme.bad)
                }
                .padding(20)
            }
        }
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this program?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteProgram() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Past workout sessions are kept; only the program template is removed.")
        }
    }

    private var headerCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Label(program.type.label, systemImage: program.type.symbol)
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.accent)
                    if program.isActive { Pill(text: "ACTIVE", color: Theme.good, filled: true) }
                }
                if !program.notes.isEmpty {
                    Text(program.notes)
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func dayCard(_ day: ProgramDay) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text(day.name)
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                ForEach(day.orderedExercises) { ex in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(ex.name)
                                    .font(Theme.rounded(15, .semibold))
                                    .foregroundStyle(Theme.ink)
                                if ex.isAccessory { Pill(text: "accessory", color: Theme.steel) }
                            }
                            Text("\(ex.sets) × \(ex.reps) · start \(settings.weight(ex.startingWeightKg)) · +\(settings.weight(ex.incrementKg))")
                                .font(Theme.rounded(12))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        MuscleBadge(group: ex.muscleGroup)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func setActive() {
        for p in allPrograms where p.isActive { p.isActive = false }
        program.isActive = true
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
    }

    private func deleteProgram() {
        context.delete(program)
        try? context.save()
        Haptics.warning(settings.hapticsEnabled)
        dismiss()
    }
}
