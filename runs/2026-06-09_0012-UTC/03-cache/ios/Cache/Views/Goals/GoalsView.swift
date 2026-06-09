import SwiftUI
import SwiftData

struct GoalsView: View {
    @Query(sort: \Goal.sortIndex) private var goals: [Goal]
    @AppStorage("cache.symbol") private var symbol = "$"
    @AppStorage("cache.hideComplete") private var hideComplete = false
    @State private var adding = false

    private var visible: [Goal] {
        goals.filter { !$0.isArchived && (!hideComplete || !$0.isComplete) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if goals.filter({ !$0.isArchived }).isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "target",
                                       title: "No goals yet",
                                       message: "Create your first savings goal and start watching it grow.")
                            .glassCard().padding(20)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            overviewCard
                            ForEach(visible) { goal in
                                NavigationLink { GoalDetailView(goal: goal) } label: {
                                    GoalCard(goal: goal, symbol: symbol)
                                }
                                .buttonStyle(.plain)
                            }
                            if visible.isEmpty {
                                Text("All goals complete — nice work.")
                                    .font(.subheadline).foregroundStyle(Brand.text3)
                                    .padding(.top, 8)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); adding = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New goal")
                }
            }
            .sheet(isPresented: $adding) { GoalEditorView(goal: nil, nextIndex: goals.count) }
        }
    }

    private var overviewCard: some View {
        let active = goals.filter { !$0.isArchived }
        let saved = SavingsEngine.totalSaved(active)
        let target = SavingsEngine.totalTarget(active)
        let pct = target > 0 ? min(saved / target, 1) : 0
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Total saved")
                Text(Money.string(saved, symbol: symbol))
                    .font(Brand.mono(34, weight: .bold))
                    .foregroundStyle(Brand.text)
                ProgressView(value: pct)
                    .tint(Brand.live)
                HStack {
                    Text("of \(Money.string(target, symbol: symbol)) across \(active.count) goal\(active.count == 1 ? "" : "s")")
                        .font(.caption).foregroundStyle(Brand.text3)
                    Spacer()
                    Text("\(Int(pct * 100))%").font(Brand.mono(13)).foregroundStyle(Brand.text2)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct GoalCard: View {
    let goal: Goal
    let symbol: String

    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                ProgressRing(progress: goal.progress, lineWidth: 8, tint: goal.color.color, size: 72) {
                    AnyView(
                        Image(systemName: goal.isComplete ? "checkmark" : goal.symbol.systemName)
                            .font(.system(size: 22))
                            .foregroundStyle(goal.color.color)
                    )
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.name).font(.headline).foregroundStyle(Brand.text)
                    Text("\(Money.string(goal.saved, symbol: symbol)) of \(Money.string(goal.targetAmount, symbol: symbol))")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                    trackLabel
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(Brand.text3)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(goal.name), \(Int(goal.progress * 100)) percent saved")
    }

    @ViewBuilder private var trackLabel: some View {
        switch SavingsEngine.track(for: goal) {
        case .complete:
            Label("Complete", systemImage: "checkmark.seal.fill").font(.caption).foregroundStyle(Brand.live)
        case .onTrack:
            Label("On track", systemImage: "checkmark.circle").font(.caption).foregroundStyle(Brand.live)
        case .behind:
            Label("Behind plan", systemImage: "exclamationmark.circle").font(.caption).foregroundStyle(Brand.warn)
        case .noTarget:
            Label("No deadline", systemImage: "infinity").font(.caption).foregroundStyle(Brand.text3)
        case .noPace:
            Label("Add a deposit", systemImage: "plus.circle").font(.caption).foregroundStyle(Brand.text3)
        }
    }
}
