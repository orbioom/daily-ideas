import SwiftUI
import SwiftData

/// Tab 2 — split a lump sum across goals. Pro feature.
struct AllocateScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro
    @Query(sort: \Goal.priority) private var allGoals: [Goal]

    @State private var amountText = ""
    @State private var strategy: AllocationStrategy = .proportionalToNeed
    @State private var selectedIDs: Set<UUID> = []
    @State private var showingPaywall = false
    @State private var didApply = false
    @State private var appliedSummary = ""

    private var activeGoals: [Goal] {
        allGoals.filter { !$0.isArchived }
    }

    private var chosenGoals: [Goal] {
        activeGoals.filter { selectedIDs.contains($0.id) }
    }

    private var parsedLump: Double? {
        let cleaned = amountText.replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard let value = Double(cleaned), value > 0 else { return nil }
        return value
    }

    private var plan: AllocationPlan? {
        guard let lump = parsedLump, !chosenGoals.isEmpty else { return nil }
        return AllocationEngine.plan(lump: lump, goals: chosenGoals, strategy: strategy)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if !pro.isPro {
                    lockedState
                } else if activeGoals.isEmpty {
                    EmptyStateView(
                        symbol: "square.split.2x2",
                        title: "No goals to fund yet",
                        message: "Create a savings goal first, then come back to split a lump sum across them."
                    )
                } else {
                    formContent
                }
            }
            .navigationTitle("Allocate")
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .onAppear {
                strategy = settings.defaultStrategy
                if selectedIDs.isEmpty {
                    selectedIDs = Set(activeGoals.map { $0.id })
                }
            }
            .alert("Allocation applied", isPresented: $didApply) {
                Button("Done", role: .cancel) { }
            } message: {
                Text(appliedSummary)
            }
        }
    }

    private var lockedState: some View {
        VStack(spacing: 18) {
            EmptyStateView(
                symbol: "lock.fill",
                title: "Smart Allocation is a Pro feature",
                message: "Spread a bonus, refund, or any lump sum across your goals — by need, evenly, or by priority — in one tap."
            )
            PrimaryButton(title: "Unlock Nest Pro", systemImage: "sparkles") {
                showingPaywall = true
            }
            .padding(.horizontal, 32)
        }
    }

    private var formContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                amountCard
                strategyCard
                goalsCard
                if let plan, plan.hasAllocation {
                    previewCard(plan)
                    PrimaryButton(title: "Apply allocation", systemImage: "checkmark") {
                        apply(plan)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var amountCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("I have this much to put away")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.inkSoft)
                HStack {
                    Text(settings.currency.symbol)
                        .font(Theme.money(28, .bold))
                        .foregroundStyle(Theme.inkSoft)
                    TextField("0", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(Theme.money(28, .bold))
                        .foregroundStyle(Theme.ink)
                }
            }
        }
    }

    private var strategyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Strategy")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.inkSoft)
                ForEach(AllocationStrategy.allCases) { s in
                    Button {
                        strategy = s
                        Haptics.select(settings.hapticsEnabled)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: s.symbolName)
                                .foregroundStyle(strategy == s ? Theme.accent : Theme.inkFaint)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(s.title)
                                    .font(Theme.rounded(15, .semibold))
                                    .foregroundStyle(Theme.ink)
                                Text(s.detail)
                                    .font(Theme.rounded(12))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                            Image(systemName: strategy == s ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(strategy == s ? Theme.accent : Theme.inkFaint)
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(strategy == s ? .isSelected : [])
                }
            }
        }
    }

    private var goalsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Apply to")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.inkSoft)
                ForEach(activeGoals) { goal in
                    Button {
                        toggle(goal)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: selectedIDs.contains(goal.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedIDs.contains(goal.id) ? Theme.accent : Theme.inkFaint)
                                .accessibilityHidden(true)
                            Image(systemName: goal.symbolName)
                                .foregroundStyle(Color.fromGoalHex(goal.colorHex))
                                .frame(width: 22)
                                .accessibilityHidden(true)
                            Text(goal.name)
                                .font(Theme.rounded(15, .medium))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text(settings.displayDecimal(GoalEngine.summary(for: goal).remaining))
                                .font(Theme.money(13))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(goal.name)
                    .accessibilityAddTraits(selectedIDs.contains(goal.id) ? .isSelected : [])
                }
            }
        }
    }

    private func previewCard(_ plan: AllocationPlan) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Preview")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text(settings.displayDecimal(plan.allocatedTotal))
                        .font(Theme.money(14, .bold))
                        .foregroundStyle(Theme.accent)
                }
                ForEach(plan.lines) { line in
                    if line.amount > 0 {
                        HStack(spacing: 10) {
                            Image(systemName: line.symbolName)
                                .foregroundStyle(Color.fromGoalHex(line.colorHex))
                                .frame(width: 20)
                                .accessibilityHidden(true)
                            Text(line.goalName)
                                .font(Theme.rounded(15))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text("+" + settings.displayDecimal(line.amount))
                                .font(Theme.money(15, .semibold))
                                .foregroundStyle(Theme.good)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(line.goalName), plus \(settings.displayDecimal(line.amount))")
                    }
                }
            }
        }
    }

    private func toggle(_ goal: Goal) {
        if selectedIDs.contains(goal.id) {
            selectedIDs.remove(goal.id)
        } else {
            selectedIDs.insert(goal.id)
        }
        Haptics.select(settings.hapticsEnabled)
    }

    private func apply(_ plan: AllocationPlan) {
        let count = AllocationEngine.apply(plan: plan, goals: chosenGoals, note: "Lump-sum allocation")
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        appliedSummary = "Added \(settings.displayDecimal(plan.allocatedTotal)) across \(count) goal\(count == 1 ? "" : "s")."
        amountText = ""
        didApply = true
    }
}
