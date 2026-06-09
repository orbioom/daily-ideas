import SwiftUI
import SwiftData

struct ActivityView: View {
    @Query(sort: \Contribution.date, order: .reverse) private var contributions: [Contribution]
    @Query private var goals: [Goal]
    @AppStorage("cache.symbol") private var symbol = "$"
    @State private var pickingGoal = false
    @State private var chosenGoal: Goal?

    private var months: [(String, [Contribution])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: contributions) { c -> Date in
            cal.date(from: cal.dateComponents([.year, .month], from: c.date)) ?? c.date
        }
        return groups.keys.sorted(by: >).map { key in
            (Format.monthYear.string(from: key), (groups[key] ?? []).sorted { $0.date > $1.date })
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if contributions.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "list.bullet",
                                       title: "No activity yet",
                                       message: goals.isEmpty ? "Create a goal first, then log your deposits here."
                                                              : "Add a contribution to start your savings log.")
                            .glassCard().padding(20)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(months, id: \.0) { month, items in
                                monthCard(month, items)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Activity")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); pickingGoal = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add contribution")
                        .disabled(goals.filter { !$0.isArchived }.isEmpty)
                }
            }
            .confirmationDialog("Add to which goal?", isPresented: $pickingGoal, titleVisibility: .visible) {
                ForEach(goals.filter { !$0.isArchived }) { goal in
                    Button(goal.name) { chosenGoal = goal }
                }
            }
            .sheet(item: $chosenGoal) { ContributionSheet(goal: $0) }
        }
    }

    private func monthCard(_ month: String, _ items: [Contribution]) -> some View {
        let net = items.reduce(0.0) { $0 + $1.amount }
        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Eyebrow(text: month)
                    Spacer()
                    Text(Money.string(net, symbol: symbol, showsSign: true))
                        .font(Brand.mono(13)).foregroundStyle(net >= 0 ? Brand.live : Brand.danger)
                }
                ForEach(items) { c in
                    HStack {
                        Circle().fill((c.goal?.color.color ?? Brand.text3))
                            .frame(width: 10, height: 10).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(c.goal?.name ?? "Removed goal")
                                .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                            Text(c.note.isEmpty ? Format.relativeDay(c.date) : c.note)
                                .font(.caption).foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        Text(Money.string(c.amount, symbol: symbol, showsSign: true))
                            .font(Brand.mono(14))
                            .foregroundStyle(c.isWithdrawal ? Brand.danger : Brand.text)
                    }
                    .padding(.vertical, 3)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}
