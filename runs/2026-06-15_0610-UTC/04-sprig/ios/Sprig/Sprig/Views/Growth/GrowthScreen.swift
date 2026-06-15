import SwiftUI
import SwiftData

/// Growth tab: picks the active child, then shows that child's growth detail.
struct GrowthScreen: View {
    @AppStorage("selectedChildID") private var selectedChildID = ""
    @Query(sort: \Child.createdAt, order: .forward) private var children: [Child]

    var body: some View {
        NavigationStack {
            Group {
                if children.isEmpty {
                    noChildState
                } else if let child = ActiveChild.resolve(from: children, selectedID: selectedChildID) {
                    VStack(spacing: 0) {
                        if children.count > 1 {
                            ChildPicker(children: children, selectedID: $selectedChildID)
                        }
                        GrowthDetailView(child: child)
                    }
                } else {
                    noChildState
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Growth")
        }
    }

    private var noChildState: some View {
        ScrollView {
            EmptyStateView(symbol: "chart.xyaxis.line",
                           title: "No children yet",
                           message: "Add a child on the Children tab to start tracking growth percentiles.")
                .padding(.top, 60)
        }
    }
}
