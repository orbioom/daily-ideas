import SwiftUI
import SwiftData

struct ChallengeDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allChallenges: [Challenge]
    @Bindable var challenge: Challenge

    @State private var showStopConfirm = false
    @State private var showRestartConfirm = false
    @State private var showEditor = false
    @State private var showDeleteConfirm = false

    private var isActive: Bool { challenge.isActive }
    private var dayIndex: Int { ChallengeEngine.currentDayIndex(for: challenge) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                headerCard

                if isActive {
                    statusCard
                }

                tasksSection

                actions
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(challenge.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !challenge.isBuiltIn {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { showEditor = true }
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack { ChallengeEditorView(challenge: challenge) }
        }
        .confirmationDialog("Stop this challenge?", isPresented: $showStopConfirm, titleVisibility: .visible) {
            Button("Stop challenge", role: .destructive) { stop() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your run ends and progress is cleared. The program stays in your list.")
        }
        .confirmationDialog("Restart at Day 1?", isPresented: $showRestartConfirm, titleVisibility: .visible) {
            Button("Restart", role: .destructive) { start() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears your current progress and begins again from Day 1 today.")
        }
        .confirmationDialog("Delete this challenge?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes the program and any progress.")
        }
    }

    // MARK: - Cards

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if isActive { Pill(text: "Active", tint: Brand.live, filled: true) }
                Pill(text: challenge.modeLabel,
                     tint: challenge.hardMode ? Brand.danger : Brand.info)
                if challenge.isBuiltIn { Pill(text: "Built-in", tint: Brand.text2) }
            }
            if !challenge.summary.isEmpty {
                Text(challenge.summary)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }
            HStack(spacing: 16) {
                Label("\(challenge.durationDays) days", systemImage: "calendar")
                Label("\(challenge.orderedTasks.count) tasks", systemImage: "checklist")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(Brand.text3)
            Text(challenge.hardMode
                 ? "Hard mode: miss any required task and the run resets to Day 1."
                 : "Soft mode: a missed day breaks your streak but the run continues.")
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    private var statusCard: some View {
        let prog = ChallengeEngine.progress(for: challenge)
        return HStack(spacing: 20) {
            ZStack {
                ProgressRing(progress: prog.percent, lineWidth: 10, tint: Brand.live)
                    .frame(width: 84, height: 84)
                Text("\(Int(prog.percent * 100))%")
                    .font(Brand.mono(16, weight: .bold))
                    .foregroundStyle(Brand.text)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(Format.dayOf(prog.dayIndex, prog.total))
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                Text("\(prog.passedDays) days passed")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }
            Spacer(minLength: 0)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Format.dayOf(prog.dayIndex, prog.total)), \(prog.passedDays) days passed, \(Int(prog.percent * 100)) percent complete")
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Daily tasks")
            ForEach(challenge.orderedTasks) { task in
                HStack(spacing: 12) {
                    Image(systemName: task.iconName)
                        .font(.title3)
                        .foregroundStyle(Brand.magic)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Brand.text)
                        if task.isMeasured {
                            Text("Target: \(Format.number(task.targetValue)) \(task.unit)")
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                        } else if !task.detail.isEmpty {
                            Text(task.detail)
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .glassCard(padding: 14)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            if isActive {
                Button("Restart at Day 1") { showRestartConfirm = true }
                    .buttonStyle(GlassButtonStyle())
                Button("Stop challenge") { showStopConfirm = true }
                    .buttonStyle(GlassButtonStyle())
                    .foregroundStyle(Brand.danger)
            } else {
                Button("Start challenge") { start() }
                    .buttonStyle(InkButtonStyle())
            }
            if !challenge.isBuiltIn {
                Button("Delete challenge") { showDeleteConfirm = true }
                    .buttonStyle(GlassButtonStyle())
                    .foregroundStyle(Brand.danger)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Actions

    private func start() {
        for other in allChallenges where other.persistentModelID != challenge.persistentModelID {
            other.isActive = false
        }
        for log in challenge.dayLogs { context.delete(log) }
        challenge.isActive = true
        challenge.startDate = Calendar.current.startOfDay(for: Date())
        try? context.save()
        Haptics.success()
    }

    private func stop() {
        challenge.isActive = false
        challenge.startDate = nil
        for log in challenge.dayLogs { context.delete(log) }
        try? context.save()
        Haptics.warning()
    }

    private func delete() {
        context.delete(challenge)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}
