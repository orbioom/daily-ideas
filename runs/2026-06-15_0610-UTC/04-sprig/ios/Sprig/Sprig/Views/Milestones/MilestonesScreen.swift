import SwiftUI
import SwiftData

/// Milestones tab: picks the active child, then shows that child's milestone checklist.
struct MilestonesScreen: View {
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
                        MilestonesDetailView(child: child)
                    }
                } else {
                    noChildState
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Milestones")
        }
    }

    private var noChildState: some View {
        ScrollView {
            EmptyStateView(symbol: "checklist",
                           title: "No children yet",
                           message: "Add a child on the Children tab to follow developmental milestones.")
                .padding(.top, 60)
        }
    }
}
