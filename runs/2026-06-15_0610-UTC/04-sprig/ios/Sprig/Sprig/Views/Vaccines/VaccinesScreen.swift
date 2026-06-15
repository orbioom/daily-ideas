import SwiftUI
import SwiftData

/// Vaccines tab: picks the active child, then shows that child's immunization schedule.
struct VaccinesScreen: View {
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
                        VaccinesDetailView(child: child)
                    }
                } else {
                    noChildState
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Vaccines")
        }
    }

    private var noChildState: some View {
        ScrollView {
            EmptyStateView(symbol: "cross.case.fill",
                           title: "No children yet",
                           message: "Add a child on the Children tab to follow the immunization schedule.")
                .padding(.top, 60)
        }
    }
}
