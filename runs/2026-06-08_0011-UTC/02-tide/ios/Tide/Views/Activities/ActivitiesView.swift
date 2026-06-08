import SwiftUI
import SwiftData

struct ActivitiesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Activity.order) private var activities: [Activity]
    @State private var showingNew = false
    @State private var editing: Activity?

    private var grouped: [(String, [Activity])] {
        let dict = Dictionary(grouping: activities.filter { !$0.isArchived }) { $0.category }
        return dict.keys.sorted().map { ($0, dict[$0]!.sorted { $0.order < $1.order }) }
    }
    private var archived: [Activity] { activities.filter { $0.isArchived } }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if activities.isEmpty {
                    EmptyStateView(icon: "tag.fill", title: "No activities",
                                   message: "Add activities to tag your check-ins and unlock correlations.")
                } else {
                    List {
                        ForEach(grouped, id: \.0) { cat, items in
                            Section(cat) {
                                ForEach(items) { a in
                                    activityRow(a)
                                }
                            }
                        }
                        if !archived.isEmpty {
                            Section("Archived") {
                                ForEach(archived) { a in
                                    HStack {
                                        Image(systemName: a.symbol).foregroundStyle(Brand.text3)
                                        Text(a.name).foregroundStyle(Brand.text2)
                                        Spacer()
                                        Button("Restore") { a.isArchived = false; try? context.save() }
                                            .font(.caption).buttonStyle(.borderless)
                                    }
                                    .listRowBackground(Color.clear)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Activities")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add activity")
                }
            }
            .sheet(isPresented: $showingNew) { ActivityEditView(activity: nil) }
            .sheet(item: $editing) { ActivityEditView(activity: $0) }
        }
    }

    private func activityRow(_ a: Activity) -> some View {
        HStack(spacing: 12) {
            Image(systemName: a.symbol).frame(width: 26).foregroundStyle(Brand.info)
            Text(a.name).foregroundStyle(Brand.text)
            Spacer()
            Text("\(a.entries.count)×").font(Brand.mono(11)).foregroundStyle(Brand.text3)
        }
        .listRowBackground(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { editing = a }
        .swipeActions {
            Button(role: .destructive) {
                context.delete(a); try? context.save(); Haptics.warning()
            } label: { Label("Delete", systemImage: "trash") }
            Button { a.isArchived = true; try? context.save() } label: {
                Label("Archive", systemImage: "archivebox")
            }.tint(Brand.text3)
        }
    }
}
