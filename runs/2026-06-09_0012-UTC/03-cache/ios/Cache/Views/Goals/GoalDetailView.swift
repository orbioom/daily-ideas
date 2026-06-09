import SwiftUI
import SwiftData

struct GoalDetailView: View {
    @Bindable var goal: Goal
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("cache.symbol") private var symbol = "$"

    @State private var editing = false
    @State private var addingContribution = false
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ringCard
                statsCard
                Button { Haptics.tap(); addingContribution = true } label: {
                    Label("Add contribution", systemImage: "plus")
                }
                .buttonStyle(InkButtonStyle())
                contributionsCard
                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("Delete goal", systemImage: "trash").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
                .tint(Brand.danger)
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Edit") { editing = true } }
        }
        .sheet(isPresented: $editing) { GoalEditorView(goal: goal, nextIndex: goal.sortIndex) }
        .sheet(isPresented: $addingContribution) { ContributionSheet(goal: goal) }
        .alert("Delete this goal?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) { context.delete(goal); try? context.save(); dismiss() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This removes the goal and all its contributions.") }
    }

    private var ringCard: some View {
        GlassCard {
            VStack(spacing: 14) {
                ProgressRing(progress: goal.progress, lineWidth: 14, tint: goal.color.color, size: 168) {
                    AnyView(
                        VStack(spacing: 2) {
                            Text("\(Int(goal.progress * 100))%")
                                .font(Brand.mono(34, weight: .bold)).foregroundStyle(Brand.text)
                            Image(systemName: goal.symbol.systemName)
                                .foregroundStyle(goal.color.color)
                        }
                    )
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(Int(goal.progress * 100)) percent of goal saved")

                Text("\(Money.string(goal.saved, symbol: symbol)) of \(Money.string(goal.targetAmount, symbol: symbol))")
                    .font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
                if goal.isComplete {
                    Label("Goal reached — well done", systemImage: "checkmark.seal.fill")
                        .font(.subheadline).foregroundStyle(Brand.live)
                } else {
                    Text("\(Money.string(goal.remaining, symbol: symbol)) to go")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                }
            }
        }
    }

    private var statsCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                if let target = goal.targetDate {
                    row("Target date", Format.shortDate.string(from: target), "calendar")
                    Divider().overlay(Brand.hairline)
                }
                if let req = SavingsEngine.requiredMonthly(for: goal) {
                    row("Need per month", Money.string(req, symbol: symbol), "arrow.up.forward",
                        tint: req > goal.monthlyPlan && goal.monthlyPlan > 0 ? Brand.warn : Brand.text)
                    Divider().overlay(Brand.hairline)
                }
                if goal.monthlyPlan > 0 {
                    row("Your plan", "\(Money.string(goal.monthlyPlan, symbol: symbol)) / mo", "calendar.badge.clock")
                    Divider().overlay(Brand.hairline)
                }
                projectionRow
            }
        }
    }

    @ViewBuilder private var projectionRow: some View {
        if goal.isComplete {
            row("Status", "Complete", "checkmark.seal.fill", tint: Brand.live)
        } else if let date = SavingsEngine.projectedDate(for: goal) {
            row("Projected finish", "\(Format.shortDate.string(from: date)) (\(Format.untilString(date)))",
                "flag.checkered", tint: SavingsEngine.track(for: goal) == .behind ? Brand.warn : Brand.live)
        } else {
            row("Projected finish", "Add deposits or a monthly plan", "questionmark.circle", tint: Brand.text3)
        }
    }

    private func row(_ label: String, _ value: String, _ icon: String, tint: Color = Brand.text) -> some View {
        HStack {
            Label(label, systemImage: icon).font(.subheadline).foregroundStyle(Brand.text2)
            Spacer()
            Text(value).font(.subheadline.weight(.medium)).foregroundStyle(tint)
                .multilineTextAlignment(.trailing)
        }
    }

    private var contributionsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Contributions")
                if goal.contributions.isEmpty {
                    Text("No contributions yet. Add your first deposit above.")
                        .font(.subheadline).foregroundStyle(Brand.text3)
                } else {
                    ForEach(goal.contributions.sorted { $0.date > $1.date }) { c in
                        HStack {
                            Image(systemName: c.isWithdrawal ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .foregroundStyle(c.isWithdrawal ? Brand.danger : Brand.live)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(Money.string(c.amount, symbol: symbol, showsSign: true))
                                    .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                Text(c.note.isEmpty ? Format.relativeDay(c.date) : "\(c.note) · \(Format.relativeDay(c.date))")
                                    .font(.caption).foregroundStyle(Brand.text3)
                            }
                            Spacer()
                            Button { context.delete(c); try? context.save() } label: {
                                Image(systemName: "trash").font(.caption).foregroundStyle(Brand.danger)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Delete contribution")
                        }
                        .padding(.vertical, 3)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}
