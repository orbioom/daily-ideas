import SwiftUI
import SwiftData

/// Home screen: every group with its total spend and your net, plus create/empty states.
struct GroupsListView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query(sort: \SplitGroup.createdAt, order: .reverse) private var groups: [SplitGroup]

    @State private var path: [SplitGroup] = []
    @State private var showingNewGroup = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Brand.pageBackground

                if groups.isEmpty {
                    EmptyStateView(
                        icon: "person.2",
                        title: "No groups yet",
                        message: "Create a group for a trip, a flat, or a dinner and start adding shared expenses.",
                        actionTitle: "Create a group",
                        action: { showingNewGroup = true }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(groups) { group in
                                Button {
                                    path.append(group)
                                } label: {
                                    GroupCard(group: group)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewGroup = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New group")
                }
            }
            .navigationDestination(for: SplitGroup.self) { group in
                GroupDetailView(group: group)
            }
            .sheet(isPresented: $showingNewGroup) {
                GroupEditView(group: nil)
            }
        }
    }
}

/// A single group summary card: glyph, name, member count, total, and your net.
private struct GroupCard: View {
    var group: SplitGroup

    var body: some View {
        let analysis = GroupAnalysis(group: group)
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Text(group.glyph)
                        .font(.system(size: 30))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.name)
                            .font(.headline)
                            .foregroundStyle(Brand.text)
                            .lineLimit(1)
                        Text("\(group.members.count) member\(group.members.count == 1 ? "" : "s") · \(analysis.stats.expenseCount) expense\(analysis.stats.expenseCount == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Brand.text3)
                        .accessibilityHidden(true)
                }

                Divider().overlay(Brand.glassStroke.opacity(0.4))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        SectionLabel(text: "Total spent")
                        Text(Money.string(analysis.stats.totalSpent, symbol: group.currencySymbol))
                            .font(Brand.mono(17, weight: .semibold))
                            .foregroundStyle(Brand.text)
                            .monospacedDigit()
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        SectionLabel(text: statusLabel(analysis))
                        statusValue(analysis)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(analysis))
        .accessibilityHint("Opens the group")
    }

    private func statusLabel(_ analysis: GroupAnalysis) -> String {
        analysis.isSettled ? "Status" : "Suggested transfers"
    }

    @ViewBuilder
    private func statusValue(_ analysis: GroupAnalysis) -> some View {
        if analysis.isSettled {
            Label("Settled", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.live)
                .labelStyle(.titleAndIcon)
        } else {
            Text("\(analysis.transfers.count)")
                .font(Brand.mono(17, weight: .semibold))
                .foregroundStyle(Brand.text)
                .monospacedDigit()
        }
    }

    private func accessibilityLabel(_ analysis: GroupAnalysis) -> String {
        var parts = [group.name,
                     "\(group.members.count) members",
                     "total \(Money.string(analysis.stats.totalSpent, symbol: group.currencySymbol))"]
        parts.append(analysis.isSettled ? "settled" : "\(analysis.transfers.count) suggested transfers")
        return parts.joined(separator: ", ")
    }
}
