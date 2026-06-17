import SwiftUI
import SwiftData

/// Tab 1 detail — big ring, pacing facts, contribution history, edit/archive.
struct GoalDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings

    @Bindable var goal: Goal

    @State private var showingDeposit = false
    @State private var showingWithdrawal = false
    @State private var showingEdit = false
    @State private var editingContribution: Contribution?
    @State private var showDeleteConfirm = false

    private var summary: GoalSummary { GoalEngine.summary(for: goal) }
    private var tint: Color { Color.fromGoalHex(goal.colorHex) }

    private var history: [Contribution] {
        goal.contributions.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    ringCard
                    factsCard
                    actionButtons
                    historySection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit goal", systemImage: "pencil")
                    }
                    Button {
                        toggleArchive()
                    } label: {
                        Label(goal.isArchived ? "Unarchive" : "Archive",
                              systemImage: goal.isArchived ? "tray.and.arrow.up" : "archivebox")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete goal", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("Goal options")
                }
            }
        }
        .sheet(isPresented: $showingDeposit) {
            ContributionEditorView(mode: .deposit(goal))
        }
        .sheet(isPresented: $showingWithdrawal) {
            ContributionEditorView(mode: .withdrawal(goal))
        }
        .sheet(isPresented: $showingEdit) {
            GoalEditorView(mode: .edit(goal))
        }
        .sheet(item: $editingContribution) { c in
            ContributionEditorView(mode: .edit(c))
        }
        .confirmationDialog("Delete this goal and all its history?",
                            isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteGoal() }
            Button("Cancel", role: .cancel) { }
        }
    }

    private var ringCard: some View {
        Card {
            VStack(spacing: 14) {
                ProgressRing(fraction: summary.progressFraction, color: tint, lineWidth: 16)
                    .frame(width: 168, height: 168)
                    .padding(.top, 6)
                StatusBadge(status: summary.status)
                Text("\(settings.displayDecimal(summary.saved)) saved")
                    .font(Theme.money(22, .bold))
                    .foregroundStyle(Theme.ink)
                Text("of \(settings.displayDecimal(summary.target)) target")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var factsCard: some View {
        Card {
            VStack(spacing: 0) {
                factRow("Remaining", settings.displayDecimal(summary.remaining))
                divider
                if goal.targetDate != nil {
                    factRow("Suggested monthly", settings.displayDecimal(summary.requiredMonthly))
                    divider
                    factRow("Recent pace (per month)", settings.displayDecimal(summary.recentMonthlyRate))
                    divider
                    factRow("Months to target", "\(summary.monthsRemaining)")
                } else {
                    factRow("Recent pace (per month)", settings.displayDecimal(summary.recentMonthlyRate))
                }
                if let projected = summary.projectedCompletion {
                    divider
                    factRow("Projected completion", projected.formatted(.dateTime.month().year()))
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            PrimaryButton(title: "Add", systemImage: "plus") {
                showingDeposit = true
            }
            Button {
                showingWithdrawal = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "minus")
                        .accessibilityHidden(true)
                    Text("Withdraw")
                }
                .font(Theme.rounded(17, .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Theme.hairline, lineWidth: 1.5)
                )
                .foregroundStyle(Theme.ink)
            }
        }
    }

    @ViewBuilder
    private var historySection: some View {
        SectionHeader(title: "History")
        if history.isEmpty {
            Card {
                Text("No contributions yet. Add your first one above.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            Card(padding: 4) {
                VStack(spacing: 0) {
                    ForEach(history) { c in
                        contributionRow(c)
                        if c.id != history.last?.id {
                            divider.padding(.horizontal, 12)
                        }
                    }
                }
            }
        }
    }

    private func contributionRow(_ c: Contribution) -> some View {
        let isWd = c.isWithdrawal
        return HStack(spacing: 12) {
            Image(systemName: isWd ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.system(size: 26))
                .foregroundStyle(isWd ? Theme.bad : Theme.good)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(c.date.formatted(.dateTime.month().day().year()))
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.ink)
                if !c.note.isEmpty {
                    Text(c.note)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text((isWd ? "-" : "+") + settings.display(c.amount))
                .font(Theme.money(15, .semibold))
                .foregroundStyle(isWd ? Theme.bad : Theme.good)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture { editingContribution = c }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                delete(c)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isWd ? "Withdrawal" : "Deposit") \(settings.display(c.amount)) on \(c.date.formatted(.dateTime.month().day().year()))")
        .accessibilityHint("Double tap to edit")
    }

    private var divider: some View {
        Rectangle().fill(Theme.hairline).frame(height: 1)
    }

    private func factRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(Theme.money(15, .semibold))
                .foregroundStyle(Theme.ink)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    private func toggleArchive() {
        goal.isArchived.toggle()
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }

    private func delete(_ c: Contribution) {
        context.delete(c)
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }

    private func deleteGoal() {
        context.delete(goal)
        try? context.save()
        Haptics.warning(settings.hapticsEnabled)
        dismiss()
    }
}
