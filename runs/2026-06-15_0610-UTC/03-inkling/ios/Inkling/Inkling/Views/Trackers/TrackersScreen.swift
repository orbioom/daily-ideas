import SwiftUI
import SwiftData

/// Manage every tracker: create, edit, toggle active, reorder, delete. Grouped by kind. Empty when
/// the library has been cleared.
struct TrackersScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Tracker.sortOrder) private var trackers: [Tracker]

    @State private var editing: Tracker?
    @State private var showingNew = false
    @State private var pendingDelete: Tracker?

    var body: some View {
        NavigationStack {
            Group {
                if trackers.isEmpty {
                    EmptyStateView(symbol: "checklist",
                                   title: "No trackers",
                                   message: "Add the things you want to track — symptoms, mood, sleep, anything.",
                                   actionTitle: "Add a tracker") { showingNew = true }
                } else {
                    list
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Trackers")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.select(settings.hapticsEnabled)
                        showingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add tracker")
                }
            }
            .sheet(isPresented: $showingNew) {
                TrackerEditView(tracker: nil, nextSortOrder: (trackers.map(\.sortOrder).max() ?? -1) + 1)
            }
            .sheet(item: $editing) { tracker in
                TrackerEditView(tracker: tracker, nextSortOrder: tracker.sortOrder)
            }
            .confirmationDialog("Delete this tracker?",
                                isPresented: deleteDialogBinding,
                                titleVisibility: .visible) {
                Button("Delete tracker & its history", role: .destructive) { confirmDelete() }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("This permanently removes \(pendingDelete?.name ?? "this tracker") and all its log entries.")
            }
        }
    }

    private var list: some View {
        List {
            Section {
                Text("Drag to reorder. Swipe a row to edit or delete. Inactive trackers stay in your history but won't show on Today.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            ForEach(trackers) { tracker in
                row(tracker)
            }
            .onMove(perform: move)
            .onDelete(perform: requestDelete)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg.ignoresSafeArea())
        .toolbar { EditButton() }
    }

    private func row(_ tracker: Tracker) -> some View {
        HStack(spacing: 12) {
            TrackerIcon(symbol: tracker.symbolName, color: tracker.color)
            VStack(alignment: .leading, spacing: 1) {
                Text(tracker.name)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(tracker.kind.title + " · " + tracker.scaleType.title)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Toggle("", isOn: activeBinding(tracker))
                .labelsHidden()
                .tint(tracker.color)
                .accessibilityLabel("\(tracker.name) active")
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.select(settings.hapticsEnabled)
            editing = tracker
        }
        .listRowBackground(Theme.surface)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { pendingDelete = tracker } label: {
                Label("Delete", systemImage: "trash")
            }
            Button { editing = tracker } label: {
                Label("Edit", systemImage: "pencil")
            }.tint(Theme.accent)
        }
    }

    // MARK: Actions

    private func activeBinding(_ tracker: Tracker) -> Binding<Bool> {
        Binding(
            get: { tracker.isActive },
            set: { newValue in
                tracker.isActive = newValue
                try? context.save()
                Haptics.select(settings.hapticsEnabled)
            }
        )
    }

    private func move(_ indices: IndexSet, _ newOffset: Int) {
        var ordered = trackers
        ordered.move(fromOffsets: indices, toOffset: newOffset)
        for (i, tracker) in ordered.enumerated() {
            tracker.sortOrder = i
        }
        try? context.save()
        Haptics.select(settings.hapticsEnabled)
    }

    private func requestDelete(_ indices: IndexSet) {
        if let first = indices.first, first < trackers.count {
            pendingDelete = trackers[first]
        }
    }

    private var deleteDialogBinding: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }

    private func confirmDelete() {
        guard let tracker = pendingDelete else { return }
        context.delete(tracker)   // cascade removes its entries
        try? context.save()
        Haptics.warning(settings.hapticsEnabled)
        pendingDelete = nil
    }
}
