import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @EnvironmentObject private var proStore: ProStore

    @Query(sort: \Board.sortIndex, order: .forward)
    private var allBoards: [Board]

    @State private var showPaywall = false

    private var activeBoards: [Board] { allBoards.filter { !$0.isArchived } }

    var body: some View {
        NavigationStack {
            Group {
                if !proStore.isPro {
                    InsightsLockedView { showPaywall = true }
                } else if activeBoards.isEmpty {
                    EmptyStateView(
                        symbol: "chart.bar.xaxis",
                        title: "No data yet",
                        message: "Create boards and complete cards to see your throughput and breakdowns here."
                    )
                } else {
                    InsightsContentView(boards: activeBoards)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Insights")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }
}

private struct InsightsLockedView: View {
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accentSoft).frame(width: 110, height: 110)
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            Text("Insights is a Pro feature")
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("See cards completed per week, column breakdowns, your busiest board, and overdue/due-soon tiles.")
                .font(.body)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: onUnlock) {
                Text("Unlock Lane Pro")
                    .font(Theme.rounded(16, .semibold))
                    .padding(.horizontal, 26)
                    .padding(.vertical, 13)
                    .background(Theme.accent, in: Capsule())
                    .foregroundStyle(.white)
            }
            Spacer()
            Spacer()
        }
        .padding()
    }
}
