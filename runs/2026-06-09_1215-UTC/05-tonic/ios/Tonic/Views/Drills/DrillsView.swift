import SwiftUI
import SwiftData

/// Lists built-in and custom drills. Tap to edit; swipe to delete custom drills;
/// the plus button creates a new one.
struct DrillsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Drill.sortIndex), SortDescriptor(\Drill.createdAt)])
    private var drills: [Drill]
    @AppStorage("tonic.defaultRootMode") private var defaultRootMode = RootMode.fixedC.rawValue

    @State private var newDrill: Drill?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if drills.isEmpty {
                    EmptyStateView(icon: "slider.horizontal.3",
                                   title: "No drills",
                                   message: "Create a drill to choose which intervals, chords, or scales you want to train.")
                        .glassCard()
                } else {
                    ForEach(drills) { drill in
                        NavigationLink {
                            DrillEditorView(drill: drill)
                        } label: {
                            DrillRow(drill: drill)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if !drill.isBuiltIn {
                                Button(role: .destructive) {
                                    delete(drill)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Drills")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    createDrill()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New drill")
            }
        }
        .navigationDestination(item: $newDrill) { drill in
            DrillEditorView(drill: drill, isNew: true)
        }
    }

    private func createDrill() {
        let nextIndex = (drills.map(\.sortIndex).max() ?? 0) + 1
        let drill = Drill(name: "New Drill",
                          type: .interval,
                          enabledKeys: Drill.defaultKeys(for: .interval),
                          direction: .ascending,
                          rootMode: RootMode(rawValue: defaultRootMode) ?? .fixedC,
                          isBuiltIn: false,
                          sortIndex: nextIndex)
        context.insert(drill)
        try? context.save()
        Haptics.tap()
        newDrill = drill
    }

    private func delete(_ drill: Drill) {
        context.delete(drill)
        try? context.save()
        Haptics.warning()
    }
}
